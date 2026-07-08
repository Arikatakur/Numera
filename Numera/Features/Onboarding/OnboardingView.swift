import SwiftUI

/// First-run setup, shown once after sign-up (before the main tabs) while
/// `AppSettings.hasCompletedOnboarding` is false. Ten calm, premium steps that
/// get a new user to value: currency, month cycle, first account, categories,
/// a first transaction, an optional reminder, and a non-blocking Pro preview.
struct OnboardingView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(AuthManager.self) private var authManager

    @State private var model = OnboardingModel()
    @State private var stepIndex = 0
    @State private var forward = true
    @State private var phase: Phase = .loading

    private enum Phase { case loading, flow }

    private let steps = OnboardingStep.allCases

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            switch phase {
            case .loading:
                ProgressView()
                    .tint(AppColors.accent)
            case .flow:
                flow
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeOut(duration: 0.3), value: phase)
        .task { await prepare() }
    }

    // MARK: - Flow chrome

    private var flow: some View {
        VStack(spacing: AppSpacing.lg) {
            topBar
                .padding(.top, AppSpacing.sm)

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var topBar: some View {
        HStack(spacing: AppSpacing.base) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(stepIndex == 0 ? 0 : 1)
            .disabled(stepIndex == 0)
            .accessibilityHidden(stepIndex == 0)

            OnboardingProgressBar(current: stepIndex, total: steps.count)
        }
        .padding(.horizontal, AppSpacing.screenMargin)
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch steps[stepIndex] {
            case .welcome:          WelcomeStep(onNext: next)
            case .privacy:          PrivacyStep(onNext: next)
            case .currency:         CurrencyStep(model: model, onNext: next)
            case .monthStart:       MonthStartStep(model: model, onNext: next)
            case .account:          MainAccountStep(model: model, onNext: next)
            case .categories:       CategoriesStep(onNext: next)
            case .firstTransaction: FirstTransactionStep(model: model, onNext: next)
            case .reminder:         ReminderStep(model: model, onNext: next)
            case .pro:              ProPreviewStep(onNext: next)
            case .done:             DoneStep(onFinish: complete)
            }
        }
        .id(stepIndex)
        .transition(.asymmetric(
            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
            removal:   .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Navigation

    private func next() {
        guard stepIndex < steps.count - 1 else { return }
        withAnimation(.smooth(duration: 0.35)) {
            forward = true
            stepIndex += 1
        }
    }

    private func back() {
        guard stepIndex > 0 else { return }
        Haptics.tap()
        withAnimation(.smooth(duration: 0.35)) {
            forward = false
            stepIndex -= 1
        }
    }

    private func complete() {
        Haptics.success()
        Task { await authManager.markOnboardingComplete() }
    }

    // MARK: - Preparation

    /// Loads the user's seeded data (categories + Main account) so the setup
    /// steps can confirm rather than duplicate. Returning users with existing
    /// transactions skip onboarding entirely.
    private func prepare() async {
        model.currencyCode = settings.currencyCode
        model.customStartDay = settings.monthStartDay

        if !store.hasLoaded && !store.isLoading {
            await store.bootstrap()
        }

        // Someone who already has data isn't a first-run user — don't gate them
        // (belt-and-braces alongside the migration's backfill).
        if !store.transactions.isEmpty {
            await authManager.markOnboardingComplete()
            return
        }

        // Confirm an already-customized account; otherwise keep the friendly
        // spec defaults (Main / 💳) and let the account step rename the seed.
        if let existing = store.accounts.first {
            let untouchedSeed = existing.name == "Main account" && existing.balance == 0
            if !untouchedSeed {
                model.accountName = existing.name
                model.accountEmoji = existing.emoji
            }
        }

        phase = .flow
    }
}

/// Ordered first-run steps.
enum OnboardingStep: Int, CaseIterable {
    case welcome, privacy, currency, monthStart, account
    case categories, firstTransaction, reminder, pro, done
}

#Preview {
    OnboardingView()
        .environment(AuthManager())
        .environment(DataStore.emptyPreview())
        .environment(AppSettings.shared)
        .environment(PremiumManager.preview())
}
