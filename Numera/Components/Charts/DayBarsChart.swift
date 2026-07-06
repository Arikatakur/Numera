import SwiftUI

/// One thin rounded bar per day with a dashed average line and compact axis
/// labels (Quanto Activity hero chart).
struct DayBarsChart: View {
    /// One value per day, in period order.
    let values: [Double]
    /// Same count as `values`; empty strings are skipped (sparse axis).
    let labels: [String]
    var average: Double?
    var barColor: Color = AppColors.accent
    var height: CGFloat = 160

    private var maxValue: Double { max(values.max() ?? 0, 1) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .top) {
                bars

                Text(MoneyFormatter.compact(maxValue))
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let average, average > 0 {
                    let y = height * (1 - CGFloat(min(1, average / maxValue)))
                    HorizontalDashLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundColor(Color.white.opacity(0.45))
                        .frame(height: 1)
                        .offset(y: y)

                    Text(MoneyFormatter.compact(average))
                        .font(.system(size: 12))
                        .monospacedDigit()
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(y: y - 18)
                }
            }
            .frame(height: height)

            HStack(alignment: .top, spacing: 3) {
                ForEach(values.indices, id: \.self) { index in
                    // Single line at natural width — two-digit days (16, 23, 30)
                    // must never wrap onto a second line in the narrow per-day
                    // cell. Labels are sparse, so overflow into empty cells is fine.
                    Text(labels.indices.contains(index) ? labels[index] : "")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(values.indices, id: \.self) { index in
                let value = values[index]
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(value > 0 ? barColor : Color.white.opacity(0.07))
                        .frame(height: value > 0 ? max(6, height * CGFloat(value / maxValue)) : 4)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }
}

private struct HorizontalDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
