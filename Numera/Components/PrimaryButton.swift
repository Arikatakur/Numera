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
                .background(AppColors.accent)
                .cornerRadius(AppRadius.pill)
        }
    }
}

/// Quanto-style floating (+): a circle pinned to the bottom-right, hovering
/// above the glass tab bar.
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
                .background(AppColors.accent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
                .shadow(color: AppColors.accent.opacity(0.25), radius: 24, x: 0, y: 6)
        }
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
        Text(label)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? color : AppColors.surfaceElevated)
            .cornerRadius(AppRadius.pill)
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : AppColors.borderGlass, lineWidth: 1)
            )
    }
}
