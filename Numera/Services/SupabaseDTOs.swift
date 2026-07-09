import Foundation

// Wire-format structs for PostgREST. Property names match column names, so no
// CodingKeys are needed. Dates travel as ISO-8601 strings (parsed manually —
// Postgres emits 0–6 fractional-second digits, which trips the stock decoders).

enum SupaDate {
    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ raw: String) -> Date {
        if let d = isoFractional.date(from: raw) { return d }
        if let d = iso.date(from: raw) { return d }
        // Normalize fractional seconds to exactly 3 digits.
        if let dotIndex = raw.firstIndex(of: ".") {
            let tail = raw[raw.index(after: dotIndex)...]
            if let tzIndex = tail.firstIndex(where: { $0 == "+" || $0 == "-" || $0 == "Z" }) {
                let fraction = String(tail[..<tzIndex].prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
                let normalized = String(raw[..<dotIndex]) + "." + fraction + String(tail[tzIndex...])
                if let d = isoFractional.date(from: normalized) { return d }
            }
        }
        return .now
    }

    static func string(from date: Date) -> String {
        isoFractional.string(from: date)
    }
}

// MARK: - profiles

/// The subset of the `profiles` row the app reads and writes. Used both to
/// decode the first-run flag (`select`) and to persist it (`update`).
struct ProfileFlagsDTO: Codable {
    var has_completed_onboarding: Bool
}

// MARK: - transactions

struct TransactionDTO: Codable {
    var id: UUID
    var user_id: UUID
    var type: String
    var amount: Decimal
    var category_id: UUID?
    var title: String
    var note: String?
    var date: String
    var account_id: UUID?
    var account_name: String

    init(_ tx: Transaction, userId: UUID) {
        id = tx.id
        user_id = userId
        type = tx.type.rawValue
        amount = tx.amount
        category_id = tx.categoryId
        title = tx.title
        note = tx.note
        date = SupaDate.string(from: tx.date)
        account_id = tx.accountId
        account_name = tx.accountName
    }

    var model: Transaction {
        Transaction(
            id: id,
            type: TransactionType(rawValue: type) ?? .expense,
            amount: amount,
            categoryId: category_id,
            title: title,
            note: note,
            date: SupaDate.parse(date),
            accountId: account_id,
            accountName: account_name
        )
    }
}

// MARK: - categories

struct CategoryDTO: Codable {
    var id: UUID
    var user_id: UUID
    var name: String
    var emoji: String
    var color: String
    var kind: String
    var sort_order: Int
    var is_default: Bool

    init(_ category: UserCategory, userId: UUID) {
        id = category.id
        user_id = userId
        name = category.name
        emoji = category.emoji
        color = category.colorHex
        kind = category.kind.rawValue
        sort_order = category.sortOrder
        is_default = category.isDefault
    }

    var model: UserCategory {
        UserCategory(
            id: id,
            name: name,
            emoji: emoji,
            colorHex: color,
            kind: CategoryKind(rawValue: kind) ?? .expense,
            sortOrder: sort_order,
            isDefault: is_default
        )
    }
}

// MARK: - accounts

struct AccountDTO: Codable {
    var id: UUID
    var user_id: UUID
    var name: String
    var balance: Decimal
    var emoji: String

    init(_ account: Account, userId: UUID) {
        id = account.id
        user_id = userId
        name = account.name
        balance = account.balance
        emoji = account.emoji
    }

    var model: Account {
        Account(id: id, name: name, balance: balance, emoji: emoji)
    }
}

// MARK: - budgets

struct BudgetDTO: Codable {
    var id: UUID
    var user_id: UUID
    var category_id: UUID?
    var amount: Decimal
    var month_start: String?

    init(_ budget: Budget, userId: UUID) {
        id = budget.id
        user_id = userId
        category_id = budget.categoryId
        amount = budget.amount
        month_start = nil
    }

    var model: Budget {
        Budget(id: id, categoryId: category_id, amount: amount)
    }
}

// MARK: - recurring rules

struct RecurringRuleDTO: Codable {
    var id: UUID
    var user_id: UUID
    var type: String
    var amount: Decimal
    var category_id: UUID?
    var title: String
    var note: String?
    var account_id: UUID?
    var account_name: String
    var frequency: String
    var next_run: String
    var is_active: Bool

    init(_ rule: RecurringRule, userId: UUID) {
        id = rule.id
        user_id = userId
        type = rule.type.rawValue
        amount = rule.amount
        category_id = rule.categoryId
        title = rule.title
        note = rule.note
        account_id = rule.accountId
        account_name = rule.accountName
        frequency = rule.frequency.rawValue
        next_run = SupaDate.string(from: rule.nextRun)
        is_active = rule.isActive
    }

    var model: RecurringRule {
        RecurringRule(
            id: id,
            type: TransactionType(rawValue: type) ?? .expense,
            amount: amount,
            categoryId: category_id,
            title: title,
            note: note,
            accountId: account_id,
            accountName: account_name,
            frequency: RecurrenceFrequency(rawValue: frequency) ?? .monthly,
            nextRun: SupaDate.parse(next_run),
            isActive: is_active
        )
    }
}
