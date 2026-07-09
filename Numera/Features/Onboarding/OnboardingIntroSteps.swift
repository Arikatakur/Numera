import SwiftUI

// MARK: - 1. Welcome

struct WelcomeStep: View {
    var onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    // Brand mark — same identity as the sign-in screen, not a
                    // generic illustration.
                    HStack(spacing: 10) {
                        Image("numera-mark")
                            .resizable()
                            .aspectRatio(64.0 / 57.0, contentMode: .fit)
                            .frame(height: 24)
                        Text("NUMERA")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .kerning(3)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppSpacing.sm)

                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Track expenses fast.")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Understand your money clearly. Stay in control privately.")
                            .font(.system(size: 17, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        OnboardingValueProp(symbol: "bolt.fill", title: "Add expenses in seconds")
                        OnboardingValueProp(symbol: "chart.pie.fill", title: "See where your money goes")
                        OnboardingValueProp(symbol: "lock.fill", title: "Private by design")
                    }
                    .padding(.top, AppSpacing.xs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.bottom, AppSpacing.lg)
            }

            PrimaryButton(title: "Get started") {
                Haptics.tap()
                onNext()
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.bottom, AppSpacing.sm)
        }
    }
}

// MARK: - 2. Privacy

struct PrivacyStep: View {
    var onNext: () -> Void

    var body: some View {
        OnboardingScaffold(
            badge: "lock.shield.fill",
            title: "Private by design",
            subtitle: "Numera is not a banking app. You enter only what you want to track."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                OnboardingValueProp(
                    symbol: "building.columns",
                    title: "No bank connection required",
                    detail: "Nothing is linked. You stay in charge of every entry."
                )
                OnboardingValueProp(
                    symbol: "hand.raised.fill",
                    title: "No ads or tracking",
                    detail: "Your spending is yours — we don't sell or profile it."
                )
                OnboardingValueProp(
                    symbol: "eye.slash.fill",
                    title: "Hide balances anytime",
                    detail: "Blur every amount with one tap from Settings."
                )
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            PrimaryButton(title: "Continue") {
                Haptics.tap()
                onNext()
            }
        }
    }
}

// MARK: - 9. Pro preview (non-blocking)

struct ProPreviewStep: View {
    @Environment(PremiumManager.self) private var premium
    var onNext: () -> Void

    @State private var showPaywall = false

    var body: some View {
        OnboardingScaffold(
            badge: "sparkles",
            title: "Go further with Numera Pro",
            subtitle: "Unlock budgets, safe-to-spend, recurring transactions, and CSV export."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                OnboardingValueProp(symbol: "chart.bar.fill", title: "Budgets & safe-to-spend",
                                    detail: "Set a monthly budget and category limits.")
                OnboardingValueProp(symbol: "arrow.triangle.2.circlepath", title: "Recurring transactions",
                                    detail: "Auto-log rent, salary and subscriptions.")
                OnboardingValueProp(symbol: "square.and.arrow.up", title: "CSV export",
                                    detail: "Take your full history anywhere, anytime.")

                Text("Everything else in Numera is free. You can explore Pro whenever you like.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            if premium.isPremium {
                PrimaryButton(title: "Continue") {
                    Haptics.success()
                    onNext()
                }
            } else {
                PrimaryButton(title: "View Pro") {
                    Haptics.tap()
                    showPaywall = true
                }
                OnboardingSecondaryButton(title: "Maybe later", action: onNext)
            }
        }
        // Non-blocking: the paywall only appears on an explicit tap.
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

// MARK: - 10. Done

struct DoneStep: View {
    var onFinish: () -> Void

    var body: some View {
        OnboardingScaffold(
            badge: "checkmark.seal.fill",
            title: "You're ready",
            subtitle: "Start with Home, or tap + anytime to add a transaction."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                OnboardingValueProp(symbol: "house.fill", title: "Home shows your month at a glance")
                OnboardingValueProp(symbol: "plus.circle.fill", title: "Tap + to add a transaction anytime")
                OnboardingValueProp(symbol: "chart.pie.fill", title: "Insights update as you spend")
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            PrimaryButton(title: "Go to Home", action: onFinish)
        }
    }
}

#Preview("Welcome") {
    ZStack { AppColors.background.ignoresSafeArea(); WelcomeStep(onNext: {}) }
        .preferredColorScheme(.dark)
}

#Preview("Privacy") {
    ZStack { AppColors.background.ignoresSafeArea(); PrivacyStep(onNext: {}) }
        .preferredColorScheme(.dark)
}

#Preview("Pro") {
    ZStack { AppColors.background.ignoresSafeArea(); ProPreviewStep(onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(PremiumManager.preview())
}

#Preview("Done") {
    ZStack { AppColors.background.ignoresSafeArea(); DoneStep(onFinish: {}) }
        .preferredColorScheme(.dark)
}
