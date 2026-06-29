import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case expense  = "Expense"
    case income   = "Income"
    case transfer = "Transfer"
}

enum Category: String, CaseIterable, Codable, Identifiable {
    case food        = "Food"
    case coffee      = "Coffee"
    case transport   = "Transport"
    case groceries   = "Groceries"
    case leisure     = "Leisure"
    case health      = "Health"
    case shopping    = "Shopping"
    case tech        = "Tech"
    case travel      = "Travel"
    case income      = "Income"
    case investment  = "Investment"
    case other       = "Other"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .food:       return "fork.knife"
        case .coffee:     return "cup.and.saucer"
        case .transport:  return "car.fill"
        case .groceries:  return "cart.fill"
        case .leisure:    return "film.fill"
        case .health:     return "cross.case.fill"
        case .shopping:   return "bag.fill"
        case .tech:       return "laptopcomputer"
        case .travel:     return "airplane"
        case .income:     return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .other:      return "ellipsis"
        }
    }
}

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var type: TransactionType
    var amount: Decimal
    var category: Category
    var title: String
    var note: String?
    var date: Date
    var accountName: String

    var isExpense: Bool { type == .expense }
    var signedAmount: Decimal { isExpense ? -amount : amount }
}
