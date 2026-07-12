import SwiftUI

/// Quanto-style announcement card ("Numera just got better!"): sparkles tile,
/// headline, X to dismiss, and a white "What's new?" pill that opens
/// `WhatsNewSheet`. Home shows it until dismissed for the current version.
struct WhatsNewCard: View {
    var onWhatsNew: () -> Void = {}
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack(alignment: .top, spacing: AppSpacing.base) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Numera just got better!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Discover what's new — starting with a guided welcome for new members.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    Haptics.tap()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }

            Button {
                Haptics.tap()
                onWhatsNew()
            } label: {
                Text("What's new?")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppColors.textPrimary)
                    .clipShape(Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.lg)
        .background(
            // Mint wash over the glass so the announcement reads as a highlight
            // (intentional tint on chrome, not behind data — see SKILL.md).
            LinearGradient(
                colors: [AppColors.accent.opacity(0.16), AppColors.chartTeal.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
        )
        .liquidGlass(cornerRadius: AppRadius.card)
    }
}

/// Release highlights behind the "What's new?" button.
struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What's new")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Version \(AppInfo.shortVersion)")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(.top, AppSpacing.xxl)

                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            featureRow("arrow.triangle.2.circlepath", "Recurring insights",
                                       "See your total recurring spend and a calendar of every day a bill or subscription lands. (Numera Pro)")
                            featureRow("chart.bar.xaxis", "Budget insights",
                                       "Track how much of your monthly budget is left, with a tappable history of recent periods. (Numera Pro)")
                            featureRow("sparkles", "A sharper launch",
                                       "The opening animation is faster, and the Numera mark now sits right beside the wordmark.")
                            featureRow("creditcard", "Accurate regional pricing",
                                       "Subscription prices always match your App Store country and currency.")
                            featureRow("checkmark.shield", "Privacy & account controls",
                                       "A clearer account-deletion flow and an updated privacy manifest.")
                        }

                        // Link out to the full public changelog.
                        Button {
                            Haptics.tap()
                            openURL(AppInfo.changelogURL)
                        } label: {
                            HStack(spacing: 6) {
                                Text("View full changelog")
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.accent)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Spacer().frame(height: AppSpacing.base)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                }

                PrimaryButton(title: "Continue") { dismiss() }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.bottom, AppSpacing.base)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func featureRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.base) {
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
                Text(detail)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Card") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        WhatsNewCard()
            .padding(AppSpacing.screenMargin)
    }
    .preferredColorScheme(.dark)
}

#Preview("Sheet") {
    WhatsNewSheet()
}
