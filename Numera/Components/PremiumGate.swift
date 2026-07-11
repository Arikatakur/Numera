import SwiftUI

/// Wraps a real feature card so it works fully when unlocked, but shows a
/// blurred, non-interactive preview with a lock + unlock CTA when the user
/// isn't on Numera Pro. Unlike `PremiumLockCard` (fake placeholder rows), this
/// gates the *actual* card, so subscribers see exactly what they unlocked.
struct PremiumGate<Content: View>: View {
    let isUnlocked: Bool
    /// Small caps label on the lock overlay, e.g. "RECURRING INSIGHTS".
    let title: String
    let buttonTitle: String
    let onUnlock: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isUnlocked {
            content()
        } else {
            content()
                // Preview only: no real numbers legible, nothing tappable.
                .blur(radius: 9)
                .disabled(true)
                .allowsHitTesting(false)
                .overlay { lockOverlay }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(title). \(buttonTitle)")
                .accessibilityAddTraits(.isButton)
        }
    }

    /// One tap target over the whole card — a lock, the section label, and a
    /// gradient "unlock" pill (rendered as a label, not a nested Button).
    private var lockOverlay: some View {
        Button(action: onUnlock) {
            VStack(spacing: AppSpacing.base) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(title)
                    .labelCapsStyle()
                unlockPill
            }
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.background.opacity(0.35))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var unlockPill: some View {
        HStack(spacing: 8) {
            Text(buttonTitle)
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .foregroundColor(.black)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [AppColors.chartTeal, AppColors.accent],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .frame(maxWidth: 300)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        PremiumGate(
            isUnlocked: false,
            title: "RECURRING INSIGHTS",
            buttonTitle: "Unlock recurring insights"
        ) {} content: {
            NumeraCard {
                VStack {
                    Text("Locked content preview")
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                }
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
