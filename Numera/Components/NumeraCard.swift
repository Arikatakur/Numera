import SwiftUI

/// Standard glass card containers. The glass treatment itself lives in
/// LiquidGlass.swift (`liquidGlass(cornerRadius:tintFallback:)`), which owns
/// the iOS 26 `.glassEffect` / iOS 17–25 material split in one place.
struct NumeraCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.cardPadding
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .liquidGlass(cornerRadius: AppRadius.hero)
    }
}

struct NumeraCardSmall<Content: View>: View {
    var padding: CGFloat = AppSpacing.base
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .liquidGlass(cornerRadius: AppRadius.card)
    }
}
