import Foundation

/// Sample data for SwiftUI previews only. Runtime data comes from Supabase via DataStore.
enum MockData {
    // Stable ids so transactions can reference categories/accounts across previews.
    static let foodId      = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let coffeeId    = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    static let transportId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    static let shoppingId  = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    static let techId      = UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    static let salaryId    = UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    static let mainAcctId  = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    static let cardAcctId  = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!

    static let categories: [UserCategory] = [
        UserCategory(id: foodId,      name: "Food",      emoji: "🍽️", colorHex: "#5DDBBD", kind: .expense, sortOrder: 0, isDefault: true),
        UserCategory(id: coffeeId,    name: "Coffee",    emoji: "☕",  colorHex: "#F8C46B", kind: .expense, sortOrder: 1, isDefault: true),
        UserCategory(id: transportId, name: "Transport", emoji: "🚗",  colorHex: "#6FB6FF", kind: .expense, sortOrder: 2, isDefault: true),
        UserCategory(id: shoppingId,  name: "Shopping",  emoji: "🛍️", colorHex: "#F472B6", kind: .expense, sortOrder: 3, isDefault: true),
        UserCategory(id: techId,      name: "Tech",      emoji: "💻",  colorHex: "#FDBA74", kind: .expense, sortOrder: 4, isDefault: true),
        UserCategory(id: salaryId,    name: "Salary",    emoji: "💰",  colorHex: "#B8F36A", kind: .income,  sortOrder: 0, isDefault: true),
    ]

    static let accounts: [Account] = [
        Account(id: mainAcctId, name: "Main account", balance: 2700, emoji: "🏦"),
        Account(id: cardAcctId, name: "Leisure Card", balance: 850,  emoji: "💳"),
    ]

    static let budgets: [Budget] = [
        Budget(categoryId: nil,    amount: 3000),
        Budget(categoryId: foodId, amount: 600),
        Budget(categoryId: transportId, amount: 250),
    ]

    static var transactions: [Transaction] {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: .now)! }
        return [
            Transaction(type: .expense, amount: 19.90,   categoryId: techId,      title: "Apple Music",      note: "Subscription", date: .now,       accountId: mainAcctId, accountName: "Main account"),
            Transaction(type: .expense, amount: 245.00,  categoryId: foodId,      title: "Blue Wave Sushi",  note: nil,            date: daysAgo(1), accountId: cardAcctId, accountName: "Leisure Card"),
            Transaction(type: .income,  amount: 6200.00, categoryId: salaryId,    title: "Paycheck",         note: nil,            date: daysAgo(2), accountId: mainAcctId, accountName: "Main account"),
            Transaction(type: .expense, amount: 64.50,   categoryId: transportId, title: "Uber",             note: nil,            date: daysAgo(1), accountId: mainAcctId, accountName: "Main account"),
            Transaction(type: .expense, amount: 480.20,  categoryId: foodId,      title: "Le Bernardin",     note: nil,            date: daysAgo(3), accountId: cardAcctId, accountName: "Leisure Card"),
            Transaction(type: .expense, amount: 129.00,  categoryId: shoppingId,  title: "Zara",             note: nil,            date: daysAgo(4), accountId: cardAcctId, accountName: "Leisure Card"),
            Transaction(type: .expense, amount: 5.40,    categoryId: coffeeId,    title: "Cafe Aroma",       note: nil,            date: daysAgo(4), accountId: mainAcctId, accountName: "Main account"),
        ]
    }
}
