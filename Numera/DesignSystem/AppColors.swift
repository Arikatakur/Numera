import SwiftUI

enum AppColors {
    // MARK: - Backgrounds
    static let background       = Color(hex: "#101419")
    static let surfaceCard      = Color(hex: "#101823")
    static let surfaceElevated  = Color(hex: "#151F2B")
    static let surfaceHigh      = Color(hex: "#272a30")
    static let surfaceSecondary = Color(hex: "#0B1118")

    // MARK: - Accent
    static let accent           = Color(hex: "#B8F36A")  // mint-volt primary
    static let accentDim        = Color(hex: "#9ED752")

    // MARK: - Text
    static let textPrimary      = Color(hex: "#F8FAFC")
    static let textSecondary    = Color(hex: "#9AA6B2")
    static let textTertiary     = Color(hex: "#64748B")
    static let onSurface        = Color(hex: "#E0E2EA")

    // MARK: - Semantic
    static let income           = Color(hex: "#B8F36A")
    static let expense          = Color(hex: "#FF6B6B")
    static let warning          = Color(hex: "#F8C46B")
    static let danger           = Color(hex: "#FF6B6B")

    // MARK: - Chart
    static let chartGreen       = Color(hex: "#B8F36A")
    static let chartPurple      = Color(hex: "#A78BFA")
    static let chartOrange      = Color(hex: "#FDBA74")
    static let chartPink        = Color(hex: "#F472B6")
    static let chartTeal        = Color(hex: "#5DDBBD")

    // MARK: - Borders
    static let borderGlass      = Color.white.opacity(0.08)
    static let borderSubtle     = Color.white.opacity(0.05)
}

// MARK: - Hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
