import SwiftUI

struct PrimaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                // Accent-tinted interactive glass (solid accent on iOS 17–25).
                .liquidGlassControl(Capsule(), tint: AppColors.accent, fallbackFill: AppColors.accent)
        }
        .buttonStyle(.plain)
    }
}

/// Quanto-style floating (+): a circle pinned to the bottom-right, hovering
/// above the tab bar.
struct FloatingAddButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 60, height: 60)
                .liquidGlassControl(Circle(), tint: AppColors.accent, fallbackFill: AppColors.accent)
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
                .shadow(color: AppColors.accent.opacity(0.25), radius: 24, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add transaction")
    }
}

/// Floating white pill button (Quanto "New category" / "New account").
struct FloatingPillButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 15)
                .background(AppColors.textPrimary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.4), radius: 18, x: 0, y: 10)
        }
    }
}

struct CategoryChip: View {
    let label: String
    var color: Color = AppColors.accent
    var isSelected: Bool = false

    var body: some View {
        let text = Text(label)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)

        if isSelected {
            text
                .background(color, in: Capsule())
        } else {
            text
                .liquidGlassControl(Capsule(), fallbackFill: AppColors.surfaceElevated)
        }
    }
}
