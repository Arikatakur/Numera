import SwiftUI

// MARK: - Progress

/// Small capsule step indicator pinned near the top of the flow. Filled
/// segments use the mint accent; the rest are subtle glass hairlines.
struct OnboardingProgressBar: View {
    let current: Int   // 0-based
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? AppColors.accent : Color.white.opacity(0.12))
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(.smooth(duration: 0.3), value: current)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

// MARK: - Scaffold

/// Shared page frame for every onboarding step: dark background, an optional
/// large title + subtitle header, scrollable content, and a footer (CTAs)
/// pinned safely above the home indicator. Keeps every screen feeling like
/// part of Numera rather than a marketing website.
struct OnboardingScaffold<Content: View, Footer: View>: View {
    var badge: String? = nil   // SF Symbol shown in a mint tile
    var title: String
    var subtitle: String? = nil
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    OnboardingHeader(badge: badge, title: title, subtitle: subtitle)
                        .padding(.top, AppSpacing.sm)

                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.bottom, AppSpacing.lg)
            }

            VStack(spacing: AppSpacing.md) {
                footer()
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.sm)
        }
    }
}

/// Large confident title, optional mint symbol badge, and a calm subtitle.
struct OnboardingHeader: View {
    var badge: String? = nil
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            if let badge {
                Image(systemName: badge)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                            .fill(AppColors.accent.opacity(0.12))
                    )
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Value prop row

/// SF-symbol tile + title + detail. Mirrors the What's New sheet language so
/// the intro screens feel native to the app.
struct OnboardingValueProp: View {
    let symbol: String
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: detail == nil ? .center : .top, spacing: AppSpacing.base) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.accent)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColors.accent.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                if let detail {
                    Text(detail)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Selectable option row

/// A tappable card row (currency, month-start, reminder). Selected state uses
/// the accent border + check, matching the app's list selection language.
struct OnboardingOptionRow: View {
    var emoji: String? = nil
    var symbol: String? = nil
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.select()
            action()
        } label: {
            HStack(spacing: AppSpacing.md) {
                if let emoji {
                    Text(emoji).font(.system(size: 22, design: .rounded))
                        .frame(width: 30)
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
                        .frame(width: 30)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, AppSpacing.base)
            .padding(.vertical, AppSpacing.base)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.08) : AppColors.surfaceCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(isSelected ? AppColors.accent.opacity(0.6) : AppColors.borderGlass, lineWidth: 1)
            )
            // Whole card tappable, not just the text (plain buttons otherwise
            // collapse their hit area to the drawn content).
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Secondary button

/// Outline/glass capsule for non-primary actions ("Maybe later", "Skip",
/// "Not now"), matching WelcomeView's secondary button.
struct OnboardingSecondaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.surfaceElevated, in: Capsule())
                .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
