import Foundation

@MainActor
@Observable
final class TransactionStore {
    var transactions: [Transaction] = MockData.transactions

    func add(_ tx: Transaction) {
        transactions.insert(tx, at: 0)
    }

    func delete(id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    // MARK: - Month filtering

    func transactions(forMonth month: Date) -> [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    func totalSpent(forMonth month: Date) -> Decimal {
        transactions(forMonth: month).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func totalIncome(forMonth month: Date) -> Decimal {
        transactions(forMonth: month).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    func safeToSpend(forMonth month: Date) -> Decimal {
        let budget: Decimal = 3000
        let remaining = budget - totalSpent(forMonth: month)
        let cal = Calendar.current
        let daysInMonth = Decimal(cal.range(of: .day, in: .month, for: month)?.count ?? 30)
        let dayOfMonth  = Decimal(cal.component(.day, from: month))
        let daysLeft    = max(1, daysInMonth - dayOfMonth + 1)
        return max(0, remaining / daysLeft)
    }

    // MARK: - Convenience (current month)

    var totalSpentThisMonth:  Decimal { totalSpent(forMonth: .now) }
    var totalIncomeThisMonth: Decimal { totalIncome(forMonth: .now) }
    var safeToSpendToday:     Decimal { safeToSpend(forMonth: .now) }
    var recentTransactions: [Transaction] { Array(transactions.prefix(3)) }
}
