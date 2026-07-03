import SwiftUI

/// Progress ring for budgets. `progress` may exceed 1 — the ring clamps and
/// switches to the danger color.
struct BudgetRing: View {
    let progress: Double
    var color: Color = AppColors.accent
    var lineWidth: CGFloat = 10

    private var displayColor: Color {
        progress > 1 ? AppColors.danger : color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.surfaceHigh.opacity(0.7), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0.003, progress))))
                .stroke(displayColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
