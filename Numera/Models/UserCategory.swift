import Foundation

enum CategoryKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }
    var label: String { self == .expense ? "Expense" : "Income" }
}

/// A user-owned category row (Quanto-style: emoji icon, accent color, manual order).
struct UserCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var emoji: String
    var colorHex: String
    var kind: CategoryKind
    var sortOrder: Int = 0
    var isDefault: Bool = false
}

extension UserCategory {
    /// Placeholder rendered when a transaction's category was deleted.
    static let fallback = UserCategory(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000FFFF")!,
        name: "Other", emoji: "🧾", colorHex: "#9AA6B2", kind: .expense
    )

    /// Color swatches offered in the category editor. Mirrors the SQL seed colors.
    static let palette: [String] = [
        "#B8F36A", "#5DDBBD", "#A78BFA", "#FDBA74", "#F472B6",
        "#FF6B6B", "#F8C46B", "#6FB6FF", "#38BDF8", "#C4B5FD", "#9AA6B2",
    ]

    /// Emoji suggestions shown in the category editor grid.
    static let emojiSuggestions: [String] = [
        "🍽️", "☕", "🛒", "🚗", "🛍️", "🍿", "💊", "💻", "✈️", "📅",
        "🏠", "💡", "👕", "🍻", "🎮", "🎁", "📚", "🐶", "⛽", "🚌",
        "🍔", "🍕", "🍺", "💈", "💅", "🏋️", "⚽", "🎵", "🎬", "📱",
        "🧾", "💰", "📈", "🪙", "💵", "🏦", "💳", "🧸", "🌴", "❤️",
    ]

    /// Client-side mirror of `seed_default_categories()` in SQL.
    /// Used to restore defaults after "Erase data".
    static var seedDefaults: [UserCategory] {
        let expense: [(String, String, String)] = [
            ("Food", "🍽️", "#5DDBBD"),
            ("Coffee", "☕", "#F8C46B"),
            ("Groceries", "🛒", "#B8F36A"),
            ("Transport", "🚗", "#6FB6FF"),
            ("Shopping", "🛍️", "#F472B6"),
            ("Leisure", "🍿", "#A78BFA"),
            ("Health", "💊", "#FF6B6B"),
            ("Tech", "💻", "#FDBA74"),
            ("Travel", "✈️", "#38BDF8"),
            ("Subscriptions", "📅", "#C4B5FD"),
            ("Other", "🧾", "#9AA6B2"),
        ]
        let income: [(String, String, String)] = [
            ("Salary", "💰", "#B8F36A"),
            ("Investments", "📈", "#5DDBBD"),
            ("Gifts", "🎁", "#F472B6"),
            ("Other Income", "🪙", "#9AA6B2"),
        ]
        return expense.enumerated().map { i, c in
            UserCategory(name: c.0, emoji: c.1, colorHex: c.2, kind: .expense, sortOrder: i, isDefault: true)
        } + income.enumerated().map { i, c in
            UserCategory(name: c.0, emoji: c.1, colorHex: c.2, kind: .income, sortOrder: i, isDefault: true)
        }
    }
}
