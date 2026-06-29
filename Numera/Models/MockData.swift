import Foundation

enum MockData {
    static let accounts: [Account] = [
        Account(name: "Cash Account",        balance: 2700,  sfSymbol: "banknote"),
        Account(name: "Main Savings",         balance: 12450, sfSymbol: "building.columns"),
        Account(name: "Leisure Card",         balance: 850,   sfSymbol: "creditcard"),
        Account(name: "Investment Portfolio", balance: 43200, sfSymbol: "chart.line.uptrend.xyaxis"),
    ]

    static let transactions: [Transaction] = [
        Transaction(type: .expense,  amount: 19.90,   category: .tech,       title: "Apple Music",      note: "Subscription",      date: .now,                              accountName: "Cash Account"),
        Transaction(type: .expense,  amount: 245.00,  category: .food,       title: "Blue Wave Sushi",  note: "Dining",            date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, accountName: "Leisure Card"),
        Transaction(type: .income,   amount: 6200.00, category: .income,     title: "Paycheck Deposit", note: nil,                 date: Calendar.current.date(byAdding: .day, value: -2, to: .now)!, accountName: "Main Savings"),
        Transaction(type: .expense,  amount: 1299.00, category: .shopping,   title: "Apple Store",      note: "Personal Wealth",   date: .now,                              accountName: "Cash Account"),
        Transaction(type: .income,   amount: 8450.00, category: .income,     title: "Salary Deposit",   note: nil,                 date: .now,                              accountName: "Main Savings"),
        Transaction(type: .expense,  amount: 480.20,  category: .food,       title: "Le Bernardin",     note: "Leisure Card",      date: .now,                              accountName: "Leisure Card"),
        Transaction(type: .expense,  amount: 12.99,   category: .tech,       title: "Cloud Subscription", note: "Digital Ops",   date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, accountName: "Cash Account"),
        Transaction(type: .expense,  amount: 64.50,   category: .transport,  title: "Uber Black",       note: "Business Travel",   date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!, accountName: "Cash Account"),
        Transaction(type: .income,   amount: 1120.45, category: .investment, title: "Dividend Payout",  note: "Investment Portfolio", date: Calendar.current.date(byAdding: .day, value: -7, to: .now)!, accountName: "Investment Portfolio"),
    ]

    static var totalSpentThisMonth: Decimal {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    static var totalIncomeThisMonth: Decimal {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    static var safeToSpendToday: Decimal {
        let remaining = totalIncomeThisMonth - totalSpentThisMonth
        let daysLeft = max(1, Calendar.current.range(of: .day, in: .month, for: .now)!.count - Calendar.current.component(.day, from: .now))
        return remaining / Decimal(daysLeft)
    }
}
