import Foundation

struct Account: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    /// Starting balance. Current balance = starting + income − expenses (computed in DataStore).
    var balance: Decimal
    var emoji: String = "🏦"
}

extension Account {
    static let emojiSuggestions: [String] = [
        "🏦", "💵", "💳", "📈", "💰", "🪙", "👛", "🐷", "🏠", "✈️", "🎯", "🔒",
    ]
}
