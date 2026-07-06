import SwiftUI

extension View {
    /// App Store–style frosted glass surface: a translucent material blurs the
    /// backdrop, a dark tint gives depth on the near-black background, and a
    /// hairline highlight traces the edge. Shared by every card container so the
    /// whole app reads as one glass system.
    func glassSurface(cornerRadius: CGFloat, tint: Double = 0.35) -> some View {
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
