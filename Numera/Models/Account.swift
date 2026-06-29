import Foundation

struct Account: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var balance: Decimal
    var sfSymbol: String
}
