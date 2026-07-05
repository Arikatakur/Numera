import Foundation

// Recurring transactions (Numera Pro). Rules live in Supabase `recurring_rules`;
// `materializeDueRecurring()` turns due rules into real transactions on launch.
// Optimistic local mutations with rollback, mirroring DataStore.swift.

extension DataStore {
    func addRecurringRule(_ rule: RecurringRule) async {
        recurringRules.append(rule)
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("recurring_rules").insert(RecurringRuleDTO(rule, userId: uid)).execute()
        } catch {
            recurringRules.removeAll { $0.id == rule.id }
            fail("Couldn't save the recurring rule.", error)
        }
    }

    func updateRecurringRule(_ rule: RecurringRule) async {
        guard let index = recurringRules.firstIndex(where: { $0.id == rule.id }) else { return }
        let previous = recurringRules[index]
        recurringRules[index] = rule
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("recurring_rules")
                .update(RecurringRuleDTO(rule, userId: uid))
                .eq("id", value: rule.id.uuidString)
                .execute()
        } catch {
            if let i = recurringRules.firstIndex(where: { $0.id == rule.id }) { recurringRules[i] = previous }
            fail("Couldn't update the recurring rule.", error)
        }
    }

    func deleteRecurringRule(id: UUID) async {
        guard let index = recurringRules.firstIndex(where: { $0.id == id }) else { return }
        let removed = recurringRules.remove(at: index)
        guard await requireUser() != nil else { return }
        do {
            try await client.from("recurring_rules").delete().eq("id", value: id.uuidString).execute()
        } catch {
            recurringRules.append(removed)
            fail("Couldn't delete the recurring rule.", error)
        }
    }

    /// Generate the transactions each active rule is due for, advancing its
    /// `next_run`. Idempotent: `next_run` is persisted after each batch, so
    /// re-running never double-creates. Called on bootstrap.
    func materializeDueRecurring() async {
        guard let uid = await requireUser() else { return }
        let now = Date()
        for rule in recurringRules where rule.isActive && rule.nextRun <= now {
            var working = rule
            var generated: [Transaction] = []
            var guardCount = 0
            while working.nextRun <= now && guardCount < 240 {
                generated.append(Transaction(
                    type: working.type,
                    amount: working.amount,
                    categoryId: working.categoryId,
                    title: working.title,
                    note: working.note,
                    date: working.nextRun,
                    accountId: working.accountId,
                    accountName: working.accountName
                ))
                working.nextRun = working.frequency.next(after: working.nextRun)
                guardCount += 1
            }
            guard !generated.isEmpty else { continue }
            do {
                try await client.from("transactions")
                    .insert(generated.map { TransactionDTO($0, userId: uid) })
                    .execute()
                try await client.from("recurring_rules")
                    .update(RecurringRuleDTO(working, userId: uid))
                    .eq("id", value: working.id.uuidString)
                    .execute()
                transactions.append(contentsOf: generated)
                sortTransactions()
                if let i = recurringRules.firstIndex(where: { $0.id == working.id }) { recurringRules[i] = working }
            } catch {
                fail("Couldn't apply a recurring transaction.", error)
            }
        }
    }
}
