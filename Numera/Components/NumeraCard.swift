import SwiftUI

extension View {
    /// Liquid Glass surface for the app's functional layer (cards, nav chrome).
    /// Real `.glassEffect` on iOS 26+, with a frosted `.ultraThinMaterial`
    /// treatment as the iOS 17–25 fallback so the app looks correct everywhere.
    /// Glass belongs on containers only — never behind text-heavy data
    /// (see .claude/skills/liquid-glass/SKILL.md).
    @ViewBuilder
    func glassSurface(cornerRadius: CGFloat, tint: Double = 0.35) -> some View {
        // `#if compiler(>=6.2)` keeps this compiling on older toolchains: the
        // `.glassEffect` symbol only exists in the iOS 26 SDK (Xcode 26 /
        // Swift 6.2). `#available` then gates the runtime for iOS 17–25.
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.materialSurface(cornerRadius: cornerRadius, tint: tint)
        }
        #else
        self.materialSurface(cornerRadius: cornerRadius, tint: tint)
        #endif
    }

    /// iOS 17–25 fallback: a translucent material blurs the backdrop, a dark
    /// tint gives depth on the near-black background, and a hairline highlight
    /// traces the edge.
    func materialSurface(cornerRadius: CGFloat, tint: Double = 0.35) -> some View {
        self
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.surfaceCard.opacity(tint))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.borderGlass, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct NumeraCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.cardPadding
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .glassSurface(cornerRadius: AppRadius.hero)
    }
}

struct NumeraCardSmall<Content: View>: View {
    var padding: CGFloat = AppSpacing.base
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .glassSurface(cornerRadius: AppRadius.card)
    }
}
