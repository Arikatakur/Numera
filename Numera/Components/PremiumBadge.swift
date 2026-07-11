import SwiftUI

/// Small "Premium" capsule shown next to locked rows (Quanto style).
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .bold, design: .rounded))
            Text("Premium")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundColor(AppColors.accent)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(AppColors.accent.opacity(0.14)))
        .overlay(Capsule().stroke(AppColors.accent.opacity(0.35), lineWidth: 1))
    }
}

/// Teal→mint gradient capsule CTA used on paywall and locked cards.
struct UnlockGradientButton: View {
    let title: String
    var icon: String? = "lock.fill"
    var action: () -> Void = {}

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.chartTeal, AppColors.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .contentShape(Capsule())
            .shadow(color: AppColors.chartTeal.opacity(0.35), radius: 16, x: 0, y: 8)
        }
    }
}

/// Quanto-style locked card: blurred placeholder content with a lock and an
/// unlock CTA on top.
struct PremiumLockCard: View {
    let title: String
    let buttonTitle: String
    var height: CGFloat = 210
    var onUnlock: () -> Void = {}

    var body: some View {
        ZStack {
            placeholderContent
                .blur(radius: 9)
                .clipped()
                .opacity(0.55)

            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 26, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)

                UnlockGradientButton(title: buttonTitle, icon: nil, action: onUnlock)
                    .frame(maxWidth: 300)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(AppColors.chartTeal.opacity(0.10))
        // Clip the blurred placeholder and teal wash to the card shape; on the
        // iOS 26 path the glass no longer clips content for us.
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
        .liquidGlass(cornerRadius: AppRadius.hero)
    }

    /// Fake rows suggesting the locked content.
    private var placeholderContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .labelCapsStyle()
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: AppSpacing.md) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 34, height: 34)
                    Capsule()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: index == 1 ? 140 : 100, height: 12)
                    Spacer()
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 48, height: 12)
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 20) {
            PremiumBadge()
            PremiumLockCard(title: "RECURRING INSIGHTS", buttonTitle: "Unlock recurring insights")
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
