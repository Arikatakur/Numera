import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case expense
    case income
    case transfer

    var label: String {
        switch self {
        case .expense:  return "Expense"
        case .income:   return "Income"
        case .transfer: return "Transfer"
        }
    }
}

struct Transaction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: TransactionType
    var amount: Decimal
    var categoryId: UUID?
    var title: String
    var note: String?
    var date: Date
    var accountId: UUID?
    /// Denormalized display name so history still renders if the account is deleted.
    var accountName: String = ""

    var isExpense: Bool { type == .expense }
    var signedAmount: Decimal { isExpense ? -amount : amount }
}
