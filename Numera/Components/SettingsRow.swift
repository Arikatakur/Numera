import SwiftUI

/// Rounded container for a group of settings rows (Quanto card anatomy:
/// one surface, hairline dividers between rows).
struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .glassSurface(cornerRadius: AppRadius.card)
    }
}

/// Hairline divider aligned past the icon tile.
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(AppColors.borderSubtle)
            .padding(.leading, 68)
    }
}

/// Quanto-style settings row: SF Symbol in a soft tile, title, custom trailing.
struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    var iconTint: Color = AppColors.textSecondary
    var titleColor: Color = AppColors.textPrimary
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: AppSpacing.base) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconTint)
            }
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(titleColor)
                .lineLimit(1)
            Spacer(minLength: AppSpacing.sm)
            trailing()
        }
        .padding(.horizontal, AppSpacing.base)
        .frame(minHeight: 62)
        .contentShape(Rectangle())
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(icon: String, title: String, iconTint: Color = AppColors.textSecondary, titleColor: Color = AppColors.textPrimary) {
        self.init(icon: icon, title: title, iconTint: iconTint, titleColor: titleColor) { EmptyView() }
    }
}

/// Gray value + chevron, the standard trailing accessory.
struct SettingsValueChevron: View {
    var value: String = ""

    var body: some View {
        HStack(spacing: 6) {
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

/// Section header above a SettingsCard.
struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 15))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xs)
    }
}
