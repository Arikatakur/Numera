import SwiftUI

/// Money display that follows the global currency, cents, and privacy settings.
struct MoneyText: View {
    let amount: Decimal
    var size: CGFloat = 34
    var color: Color = AppColors.textPrimary
    /// Prefix positive amounts with "+".
    var signed: Bool = false
    /// Force privacy on/off (previews, per-view overrides). nil = follow settings.
    var privacyOverride: Bool?

    @Environment(AppSettings.self) private var settings: AppSettings?

    private var display: String {
        if privacyOverride ?? settings?.isPrivate ?? false { return "••••" }
        return MoneyFormatter.string(
            amount,
            code: settings?.currencyCode ?? "USD",
            cents: settings?.displayCents ?? true,
            signed: signed
        )
    }

    var body: some View {
        Text(display)
            .moneyStyle(size: size, color: color)
    }
}
