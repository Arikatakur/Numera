import Foundation

enum RecurrenceFrequency: String, Codable, CaseIterable, Hashable {
    case weekly, monthly, yearly

    var label: String {
        switch self {
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        case .yearly:  return "Yearly"
        }
    }

    /// The next occurrence strictly after `date`.
    func next(after date: Date) -> Date {
        let cal = Calendar.current
        switch self {
        case .weekly:  return cal.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly: return cal.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:  return cal.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
}

/// A template that auto-generates a transaction each time it comes due.
/// `nextRun` is advanced (and persisted) as transactions are generated, so
/// materialization is idempotent across launches.
struct RecurringRule: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: TransactionType
    var amount: Decimal
    var categoryId: UUID?
    var title: String
    var note: String?
    var accountId: UUID?
    var accountName: String = ""
    var frequency: RecurrenceFrequency
    /// Next date a transaction should be generated for this rule.
    var nextRun: Date
    var isActive: Bool = true
}
