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
                            featureRow("hand.wave.fill", "A guided welcome",
                                       "New members set up their currency, first account and a sample expense in seconds.")
                            featureRow("sparkles", "Rounded, glassy look",
                                       "Quanto-style rounded type and Liquid Glass on every page.")
                            featureRow("chart.bar.xaxis", "Native charts",
                                       "Bars, donut and calendar are now Apple-native — smoother and clearer.")
                            featureRow("calendar", "Weekly to yearly insights",
                                       "Switch Insights between weekly, monthly, quarterly and yearly views.")
                            featureRow("clock.arrow.circlepath", "Full activity history",
                                       "Scroll back through every month and jump to any year since 2020.")
                            featureRow("arrow.triangle.2.circlepath", "Recurring transactions",
                                       "Put rent, salary and subscriptions on autopilot.")
                        }

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
