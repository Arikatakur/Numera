import Foundation
import Supabase

/// Single source of truth for user data. Optimistic local mutations with
/// Supabase persistence; failed writes roll back and surface `errorMessage`.
@MainActor
@Observable
final class DataStore {
    var categories: [UserCategory] = []
    var accounts: [Account] = []
    var transactions: [Transaction] = []   // sorted newest first
    var budgets: [Budget] = []
    var recurringRules: [RecurringRule] = []

    var isLoading = false
    var hasLoaded = false
    var errorMessage: String?

    let settings: AppSettings
    private let isPreview: Bool
    private var userId: UUID?

    init(settings: AppSettings = .shared, preview: Bool = false) {
        self.settings = settings
        self.isPreview = preview
    }

    /// Preview/mock store used by SwiftUI previews. Never touches the network.
    static func preview() -> DataStore {
        let store = DataStore(preview: true)
        store.categories = MockData.categories
        store.accounts = MockData.accounts
        store.transactions = MockData.transactions.sorted { $0.date > $1.date }
        store.budgets = MockData.budgets
        store.hasLoaded = true
        return store
    }

    /// Preview store for first-run UI: seeded categories/accounts but no
    /// transactions, so onboarding treats it as a brand-new user.
    static func emptyPreview() -> DataStore {
        let store = preview()
        store.transactions = []
        return store
    }

    var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Lifecycle

    func bootstrap() async {
        guard !isPreview else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            userId = try await client.auth.session.user.id
            let cats: [CategoryDTO] = try await client.from("categories")
                .select().order("sort_order").execute().value
            let accts: [AccountDTO] = try await client.from("accounts")
                .select().order("created_at").execute().value
            let txs: [TransactionDTO] = try await client.from("transactions")
                .select().order("date", ascending: false).execute().value
            let buds: [BudgetDTO] = try await client.from("budgets")
                .select().execute().value
            categories = cats.map(\.model)
            accounts = accts.map(\.model)
            transactions = txs.map(\.model)
            budgets = buds.map(\.model)
            hasLoaded = true
            await loadAndApplyRecurring()
        } catch {
            fail("Couldn't load your data — pull to refresh.", error)
        }
    }

    /// Loads recurring rules and generates any that are due. Resilient: if the
    /// table is missing (migration not yet applied) it's skipped, not fatal —
    /// so the rest of the app keeps working.
    func loadAndApplyRecurring() async {
        guard !isPreview, userId != nil else { return }
        do {
            let rules: [RecurringRuleDTO] = try await client.from("recurring_rules")
                .select().execute().value
            recurringRules = rules.map(\.model)
        } catch {
            #if DEBUG
            print("[DataStore] recurring load skipped — \(error)")
            #endif
            return
        }
        await materializeDueRecurring()
    }

    func reset() {
        categories = []
        accounts = []
        transactions = []
        budgets = []
        recurringRules = []
        userId = nil
        hasLoaded = false
        errorMessage = nil
    }

    // MARK: - Lookups

    func category(_ id: UUID?) -> UserCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    /// Never-nil category for display; deleted/unknown ids render as "Other".
    func displayCategory(for transaction: Transaction) -> UserCategory {
        category(transaction.categoryId) ?? .fallback
    }

    func categories(of kind: CategoryKind) -> [UserCategory] {
        categories.filter { $0.kind == kind }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func account(_ id: UUID?) -> Account? {
        guard let id else { return nil }
        return accounts.first { $0.id == id }
    }

    // MARK: - Transactions

    func addTransaction(_ tx: Transaction) async {
        transactions.append(tx)
        sortTransactions()
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("transactions").insert(TransactionDTO(tx, userId: uid)).execute()
        } catch {
            transactions.removeAll { $0.id == tx.id }
            fail("Couldn't save the transaction.", error)
        }
    }

    func updateTransaction(_ tx: Transaction) async {
        guard let index = transactions.firstIndex(where: { $0.id == tx.id }) else { return }
        let previous = transactions[index]
        transactions[index] = tx
        sortTransactions()
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("transactions")
                .update(TransactionDTO(tx, userId: uid))
                .eq("id", value: tx.id.uuidString)
                .execute()
        } catch {
            if let i = transactions.firstIndex(where: { $0.id == tx.id }) {
                transactions[i] = previous
                sortTransactions()
            }
            fail("Couldn't update the transaction.", error)
        }
    }

    func deleteTransaction(id: UUID) async {
        guard let index = transactions.firstIndex(where: { $0.id == id }) else { return }
        let removed = transactions.remove(at: index)
        guard await requireUser() != nil else { return }
        do {
            try await client.from("transactions").delete().eq("id", value: id.uuidString).execute()
        } catch {
            transactions.append(removed)
            sortTransactions()
            fail("Couldn't delete the transaction.", error)
        }
    }

    func sortTransactions() {
        transactions.sort { $0.date > $1.date }
    }

    // MARK: - Categories

    func addCategory(_ category: UserCategory) async {
        categories.append(category)
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("categories").insert(CategoryDTO(category, userId: uid)).execute()
        } catch {
            categories.removeAll { $0.id == category.id }
            fail("Couldn't save the category.", error)
        }
    }

    func updateCategory(_ category: UserCategory) async {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        let previous = categories[index]
        categories[index] = category
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("categories")
                .update(CategoryDTO(category, userId: uid))
                .eq("id", value: category.id.uuidString)
                .execute()
        } catch {
            if let i = categories.firstIndex(where: { $0.id == category.id }) {
                categories[i] = previous
            }
            fail("Couldn't update the category.", error)
        }
    }

    /// Deleting a category detaches its transactions (they render as "Other")
    /// and removes its budget — mirrors the DB's ON DELETE behaviour locally.
    func deleteCategory(id: UUID) async {
        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let removed = categories.remove(at: index)
        for i in transactions.indices where transactions[i].categoryId == id {
            transactions[i].categoryId = nil
        }
        budgets.removeAll { $0.categoryId == id }
        guard await requireUser() != nil else { return }
        do {
            try await client.from("categories").delete().eq("id", value: id.uuidString).execute()
        } catch {
            categories.append(removed)
            fail("Couldn't delete the category.", error)
        }
    }

    /// Persist a new manual order within one kind (expense or income).
    func reorderCategories(kind: CategoryKind, from source: IndexSet, to destination: Int) async {
        var ordered = categories(of: kind)
        ordered.move(fromOffsets: source, toOffset: destination)
        var changed: [UserCategory] = []
        for (index, var category) in ordered.enumerated() where category.sortOrder != index {
            category.sortOrder = index
            changed.append(category)
            if let i = categories.firstIndex(where: { $0.id == category.id }) {
                categories[i] = category
            }
        }
        guard let uid = await requireUser(), !changed.isEmpty else { return }
        do {
            for category in changed {
                try await client.from("categories")
                    .update(CategoryDTO(category, userId: uid))
                    .eq("id", value: category.id.uuidString)
                    .execute()
            }
        } catch {
            fail("Couldn't save the new order.", error)
        }
    }

    // MARK: - Accounts

    func addAccount(_ account: Account) async {
        accounts.append(account)
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("accounts").insert(AccountDTO(account, userId: uid)).execute()
        } catch {
            accounts.removeAll { $0.id == account.id }
            fail("Couldn't save the account.", error)
        }
    }

    func updateAccount(_ account: Account) async {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        let previous = accounts[index]
        accounts[index] = account
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("accounts")
                .update(AccountDTO(account, userId: uid))
                .eq("id", value: account.id.uuidString)
                .execute()
        } catch {
            if let i = accounts.firstIndex(where: { $0.id == account.id }) {
                accounts[i] = previous
            }
            fail("Couldn't update the account.", error)
        }
    }

    func deleteAccount(id: UUID) async {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        let removed = accounts.remove(at: index)
        for i in transactions.indices where transactions[i].accountId == id {
            transactions[i].accountId = nil
        }
        guard await requireUser() != nil else { return }
        do {
            try await client.from("accounts").delete().eq("id", value: id.uuidString).execute()
        } catch {
            accounts.append(removed)
            fail("Couldn't delete the account.", error)
        }
    }

    // MARK: - Budgets

    var overallBudget: Budget? {
        budgets.first { $0.categoryId == nil }
    }

    func budget(for categoryId: UUID?) -> Budget? {
        budgets.first { $0.categoryId == categoryId }
    }

    /// Insert-or-update the budget for a category (nil = overall monthly budget).
    func setBudget(categoryId: UUID?, amount: Decimal) async {
        if var existing = budget(for: categoryId) {
            let previous = existing.amount
            existing.amount = amount
            if let i = budgets.firstIndex(where: { $0.id == existing.id }) { budgets[i] = existing }
            guard let uid = await requireUser() else { return }
            do {
                try await client.from("budgets")
                    .update(BudgetDTO(existing, userId: uid))
                    .eq("id", value: existing.id.uuidString)
                    .execute()
            } catch {
                if let i = budgets.firstIndex(where: { $0.id == existing.id }) {
                    budgets[i].amount = previous
                }
                fail("Couldn't update the budget.", error)
            }
        } else {
            let budget = Budget(categoryId: categoryId, amount: amount)
            budgets.append(budget)
            guard let uid = await requireUser() else { return }
            do {
                try await client.from("budgets").insert(BudgetDTO(budget, userId: uid)).execute()
            } catch {
                budgets.removeAll { $0.id == budget.id }
                fail("Couldn't save the budget.", error)
            }
        }
    }

    func deleteBudget(id: UUID) async {
        guard let index = budgets.firstIndex(where: { $0.id == id }) else { return }
        let removed = budgets.remove(at: index)
        guard await requireUser() != nil else { return }
        do {
            try await client.from("budgets").delete().eq("id", value: id.uuidString).execute()
        } catch {
            budgets.append(removed)
            fail("Couldn't delete the budget.", error)
        }
    }

    // MARK: - Plumbing

    /// nil in previews (local-only) and when no session is available.
    func requireUser() async -> UUID? {
        guard !isPreview else { return nil }
        if let userId { return userId }
        userId = try? await client.auth.session.user.id
        if userId == nil {
            errorMessage = "Not signed in — changes weren't saved."
        }
        return userId
    }

    func fail(_ message: String, _ error: Error) {
        errorMessage = message
        #if DEBUG
        print("[DataStore] \(message) — \(error)")
        #endif
    }
}
