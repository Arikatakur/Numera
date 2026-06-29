import SwiftUI

enum AppTypography {
    // MARK: - Display (money amounts)
    static func displayMoney(size: CGFloat = 48) -> Font {
        .custom("PlusJakartaSans-Bold", size: size)
    }

    // MARK: - Headlines
    static let headlineLarge  = Font.custom("PlusJakartaSans-Bold",   size: 28)
    static let headlineMedium = Font.custom("PlusJakartaSans-SemiBold", size: 20)
    static let headlineSmall  = Font.custom("PlusJakartaSans-SemiBold", size: 17)

    // MARK: - Body
    static let bodyLarge      = Font.custom("PlusJakartaSans-SemiBold", size: 18)
    static let bodyMedium     = Font.custom("PlusJakartaSans-Regular",  size: 16)
    static let bodySmall      = Font.custom("PlusJakartaSans-Regular",  size: 14)

    // MARK: - Labels
    static let labelCaps      = Font.custom("PlusJakartaSans-Bold",    size: 12)
    static let caption        = Font.custom("PlusJakartaSans-Regular", size: 13)
}

// MARK: - Convenience modifiers
extension View {
    func moneyStyle(size: CGFloat = 34, color: Color = AppColors.textPrimary) -> some View {
        self
            .font(.system(size: size, weight: .bold, design: .default))
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
