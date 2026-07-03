import Foundation

/// One category's slice of a period — powers the Insights donut and breakdown list.
struct CategoryTotal: Identifiable {
    let category: UserCategory
    let total: Decimal
    let count: Int
    /// 0…1 share of the period's grand total.
    let share: Double

    var id: UUID { category.id }
}

extension DataStore {
    // MARK: - Periods

    var currentPeriod: Period {
        PeriodMath.period(containing: .now, startDay: settings.monthStartDay)
    }

    func shiftPeriod(_ period: Period, by months: Int) -> Period {
        PeriodMath.shift(period, by: months, startDay: settings.monthStartDay)
    }

    // MARK: - Totals

    func transactions(in period: Period) -> [Transaction] {
        transactions.filter { period.contains($0.date) }
    }

    func totalExpenses(in period: Period) -> Decimal {
        transactions(in: period)
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    func totalIncome(in period: Period) -> Decimal {
        transactions(in: period)
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }

    func net(in period: Period) -> Decimal {
        totalIncome(in: period) - totalExpenses(in: period)
    }

    /// Expenses % change vs the previous period. nil when there's no baseline.
    func expenseChange(in period: Period) -> Double? {
        let previous = totalExpenses(in: shiftPeriod(period, by: -1))
        guard previous > 0 else { return nil }
        let current = totalExpenses(in: period)
        let ratio = ((current - previous) / previous * 100) as NSDecimalNumber
        return ratio.doubleValue
    }

    // MARK: - Category breakdown

    func categoryTotals(in period: Period, kind: CategoryKind = .expense) -> [CategoryTotal] {
        let type: TransactionType = kind == .expense ? .expense : .income
        let relevant = transactions(in: period).filter { $0.type == type }
        let grand = relevant.reduce(Decimal(0)) { $0 + $1.amount }
        guard grand > 0 else { return [] }

        let groups = Dictionary(grouping: relevant) { $0.categoryId }
        return groups.map { categoryId, txs in
            let total = txs.reduce(Decimal(0)) { $0 + $1.amount }
            let share = ((total / grand) as NSDecimalNumber).doubleValue
            return CategoryTotal(
                category: category(categoryId) ?? .fallback,
                total: total,
                count: txs.count,
                share: share
            )
        }
        .sorted { $0.total > $1.total }
    }

    // MARK: - Time series

    /// Total per day for every day in the period, in order.
    func dailyTotals(in period: Period, type: TransactionType = .expense) -> [(date: Date, total: Decimal)] {
        let calendar = Calendar.current
        let relevant = transactions(in: period).filter { $0.type == type }
        let groups = Dictionary(grouping: relevant) { calendar.startOfDay(for: $0.date) }
        return PeriodMath.days(in: period).map { day in
            (day, groups[day]?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0)
        }
    }

    func highestSpendingDay(in period: Period) -> (date: Date, total: Decimal)? {
        dailyTotals(in: period)
            .filter { $0.total > 0 }
            .max { $0.total < $1.total }
    }

    /// The last `count` periods ending at `period`, oldest first.
    func monthlySeries(endingAt period: Period, count: Int) -> [(period: Period, income: Decimal, expenses: Decimal)] {
        (0..<count).reversed().map { offset in
            let p = shiftPeriod(period, by: -offset)
            return (p, totalIncome(in: p), totalExpenses(in: p))
        }
    }

    // MARK: - Accounts

    /// Starting balance + income − expenses recorded against the account.
    func currentBalance(of account: Account) -> Decimal {
        let delta = transactions
            .filter { $0.accountId == account.id && $0.type != .transfer }
            .reduce(Decimal(0)) { $0 + $1.signedAmount }
        return account.balance + delta
    }

    var totalBalance: Decimal {
        accounts.reduce(0) { $0 + currentBalance(of: $1) }
    }

    // MARK: - Budgets

    func spent(categoryId: UUID, in period: Period) -> Decimal {
        transactions(in: period)
            .filter { $0.type == .expense && $0.categoryId == categoryId }
            .reduce(0) { $0 + $1.amount }
    }

    /// Even split of what's left of the overall budget across the period's
    /// remaining days. nil when no overall budget is set.
    func safeToSpendPerDay(in period: Period) -> Decimal? {
        guard let overall = overallBudget else { return nil }
        let remaining = overall.amount - totalExpenses(in: period)
        guard remaining > 0 else { return 0 }

        let calendar = Calendar.current
        let daysLeft: Int
        if period.contains(.now) {
            let today = calendar.startOfDay(for: .now)
            daysLeft = max(1, calendar.dateComponents([.day], from: today, to: period.end).day ?? 1)
        } else {
            daysLeft = max(1, period.dayCount)
        }
        return remaining / Decimal(daysLeft)
    }
}
