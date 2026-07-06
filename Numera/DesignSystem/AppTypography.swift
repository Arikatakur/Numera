import SwiftUI

/// App-wide type: SF Pro Rounded (Quanto's soft, friendly look) via the system
/// rounded design — no bundled font files. Money keeps tabular digits.
enum AppTypography {
    // MARK: - Display (money amounts)
    static func displayMoney(size: CGFloat = 48) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    // MARK: - Headlines
    static let headlineLarge  = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineSmall  = Font.system(size: 17, weight: .semibold, design: .rounded)

    // MARK: - Body
    static let bodyLarge      = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bodyMedium     = Font.system(size: 16, design: .rounded)
    static let bodySmall      = Font.system(size: 14, design: .rounded)

    // MARK: - Labels
    static let labelCaps      = Font.system(size: 12, weight: .bold, design: .rounded)
    static let caption        = Font.system(size: 13, design: .rounded)
}

// MARK: - Convenience modifiers
extension View {
    func moneyStyle(size: CGFloat = 34, color: Color = AppColors.textPrimary) -> some View {
        self
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(color)
            .tracking(-0.5)
    }

    func labelCapsStyle(color: Color = AppColors.textSecondary) -> some View {
        self
            .font(AppTypography.labelCaps)
            .foregroundColor(color)
            .tracking(0.8)
            .textCase(.uppercase)
    }
}
