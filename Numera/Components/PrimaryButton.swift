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

struct FloatingAddButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 56, height: 56)
                .background(AppColors.accent)
                .clipShape(Circle())
                .shadow(color: AppColors.accent.opacity(0.45), radius: 20, x: 0, y: 8)
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
