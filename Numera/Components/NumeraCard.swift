import SwiftUI

struct NumeraCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.cardPadding
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppRadius.hero)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.hero)
                    .stroke(AppColors.borderGlass, lineWidth: 1)
            )
    }
}

struct NumeraCardSmall<Content: View>: View {
    var padding: CGFloat = AppSpacing.base
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(AppColors.surfaceCard)
            .cornerRadius(AppRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(AppColors.borderGlass, lineWidth: 1)
            )
    }
}
