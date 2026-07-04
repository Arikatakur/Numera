import SwiftUI
import StoreKit

/// Numera Pro paywall (Quanto anatomy, Numera identity): badge, feature
/// checklist, three pricing cards, trial footnote, gradient CTA.
struct PaywallView: View {
    @Environment(PremiumManager.self) private var premium
    @Environment(\.dismiss) private var dismiss

    @State private var selected: PremiumProduct = .yearly
    @State private var trialEligible = false

    // Replace before App Store review: standard Apple EULA + a real privacy page.
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://github.com/Arikatakur/Numera")!

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [AppColors.chartTeal.opacity(0.16), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header

                    VStack(alignment: .leading, spacing: AppSpacing.base) {
                        featureRow("Unlock budgeting", detail: "Monthly budget, category limits, safe to spend")
                        featureRow("Recurring transactions", detail: "Auto-log rent, salary, subscriptions", soon: true)
                        featureRow("Export all your data", detail: "Full CSV export, anytime")
                        featureRow("Support Numera development 🫶", detail: nil)
                    }

                    pricingCards
                        .padding(.top, AppSpacing.sm)

                    footnote

                    ctaButton

                    linksRow
                        .padding(.bottom, AppSpacing.lg)
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, AppSpacing.lg)
            }
        }
        .preferredColorScheme(.dark)
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .padding(.trailing, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.base)
        }
        .task(id: premium.products.count) {
            trialEligible = await premium.yearlyProduct?.subscription?.isEligibleForIntroOffer ?? false
        }
        .alert(
            "Purchase",
            isPresented: Binding(
                get: { premium.purchaseError != nil },
                set: { if !$0 { premium.purchaseError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(premium.purchaseError ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.accent)
            }

            Text(trialAvailable ? "Try Numera Pro for Free" : "Numera Pro")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Unlock all features with zero commitment.")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.xl)
    }

    private func featureRow(_ title: String, detail: String?, soon: Bool = false) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    if soon {
                        Text("SOON")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppColors.warning))
                    }
                }
                if let detail {
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Pricing

    /// Card layout data; fallback prices render when App Store products
    /// aren't available yet.
    private struct PriceSpec: Identifiable {
        let product: PremiumProduct
        let big: String
        let unit: String
        let fallback: String
        var id: String { product.rawValue }
    }

    private static let cardSpecs: [PriceSpec] = [
        PriceSpec(product: .monthly, big: "1", unit: "Month", fallback: "$2.99"),
        PriceSpec(product: .yearly, big: "12", unit: "Months", fallback: "$24.99"),
        PriceSpec(product: .lifetime, big: "∞", unit: "Lifetime", fallback: "$59.99"),
    ]

    private var pricingCards: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(Self.cardSpecs) { spec in
                pricingCard(spec)
            }
        }
    }

    private func pricingCard(_ spec: PriceSpec) -> some View {
        let product = premium.product(spec.product)
        let isSelected = selected == spec.product
        let price = product?.displayPrice ?? spec.fallback

        return Button {
            Haptics.select()
            selected = spec.product
        } label: {
            VStack(spacing: 5) {
                Text(spec.big)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(spec.unit)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
                Text(price)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(isSelected ? AppColors.chartTeal.opacity(0.12) : AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(isSelected ? AppColors.accent : AppColors.borderGlass, lineWidth: isSelected ? 1.5 : 1)
            )
            .overlay(alignment: .top) {
                if spec.product == .yearly, let savings = premium.yearlySavingsPercent {
                    Text("Save \(savings)%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColors.accent))
                        .offset(y: -11)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA + footnote

    private var trialAvailable: Bool {
        trialEligible && premium.yearlyProduct?.subscription?.introductoryOffer != nil
    }

    private var footnoteText: String {
        if selected == .lifetime {
            return "One-time payment. Yours forever."
        }
        if selected == .yearly, trialAvailable, let yearly = premium.yearlyProduct {
            return "14 days free, then \(yearly.displayPrice)/year. Cancel anytime."
        }
        return "Auto-renews until cancelled. Cancel anytime."
    }

    private var footnote: some View {
        Text(footnoteText)
            .font(.system(size: 13))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    @ViewBuilder
    private var ctaButton: some View {
        if premium.hasLoadedProducts && premium.products.isEmpty {
            VStack(spacing: AppSpacing.sm) {
                UnlockGradientButton(title: "Purchases unavailable", icon: nil)
                    .opacity(0.4)
                    .disabled(true)
                Text("Products aren't configured yet. On a development build, attach the Numera.storekit configuration; on TestFlight, set up products in App Store Connect.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        } else if premium.isPurchasing {
            HStack {
                Spacer()
                ProgressView().tint(AppColors.accent)
                Spacer()
            }
            .padding(.vertical, 16)
        } else {
            UnlockGradientButton(
                title: selected == .yearly && trialAvailable ? "Start my 14 day free trial" : "Unlock Numera Pro",
                icon: nil
            ) {
                buy()
            }
        }
    }

    private func buy() {
        guard let product = premium.product(selected) else { return }
        Task {
            let success = await premium.purchase(product)
            if success {
                Haptics.success()
                dismiss()
            }
        }
    }

    // MARK: - Links

    private var linksRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Link("Terms of use", destination: termsURL)
            Text("|").foregroundColor(AppColors.textTertiary)
            Link("Privacy policy", destination: privacyURL)
            Text("|").foregroundColor(AppColors.textTertiary)
            Button("Restore purchases") {
                Task {
                    await premium.restorePurchases()
                    if premium.isPremium {
                        Haptics.success()
                        dismiss()
                    }
                }
            }
        }
        .font(.system(size: 13))
        .foregroundColor(AppColors.textSecondary)
        .tint(AppColors.textSecondary)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PaywallView()
        .environment(PremiumManager.preview())
        .environment(AppSettings.shared)
}
