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
    /// Custom asset-catalog glyph (template-rendered) instead of an SF Symbol —
    /// used for brand rows like Instagram that have no SF Symbol.
    var assetIcon: String? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: AppSpacing.base) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 40, height: 40)
                if let assetIcon {
                    Image(assetIcon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundColor(iconTint)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconTint)
                }
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
        self.init(icon: icon, title: title, iconTint: iconTint, titleColor: titleColor, assetIcon: nil) { EmptyView() }
    }
}

extension SettingsRow {
    /// Row with a custom asset glyph (e.g. a brand logo) and a trailing accessory.
    init(
        assetIcon: String,
        title: String,
        iconTint: Color = AppColors.textSecondary,
        titleColor: Color = AppColors.textPrimary,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.init(icon: "", title: title, iconTint: iconTint, titleColor: titleColor, assetIcon: assetIcon, trailing: trailing)
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
