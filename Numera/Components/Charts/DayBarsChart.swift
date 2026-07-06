import SwiftUI
import Charts

/// Quanto Activity hero chart on native Swift Charts: one thin rounded bar per
/// day, a dashed average rule with its value on the right axis (no badge — tap
/// the number for the calculation explainer), and sparse day labels.
struct DayBarsChart: View {
    /// One value per day, in period order.
    let values: [Double]
    /// Same count as `values`; empty strings are skipped (sparse axis).
    let labels: [String]
    var average: Double?
    var averageExplanation: String?
    var barColor: Color = AppColors.accent
    var height: CGFloat = 160

    @State private var showAverageInfo = false

    private var maxValue: Double { max(values.max() ?? 0, 1) }

    /// Axis ceiling rounded up to 1 / 2 / 2.5 / 5 × 10ⁿ so the top label reads
    /// clean ("2.5k", not "2,286.71").
    private var axisMax: Double {
        let exponent = floor(log10(maxValue))
        let base = pow(10.0, exponent)
        let mantissa = maxValue / base
        let nice: Double = mantissa <= 1 ? 1 : mantissa <= 2 ? 2 : mantissa <= 2.5 ? 2.5 : mantissa <= 5 ? 5 : 10
        return nice * base
    }

    /// Empty days keep a tiny stub so the baseline reads as a row of dots.
    private var stub: Double { axisMax * 0.018 }

    private var dayLabelIndices: [Double] {
        labels.enumerated().compactMap { $0.element.isEmpty ? nil : Double($0.offset) }
    }

    var body: some View {
        Chart {
            ForEach(values.indices, id: \.self) { index in
                let value = values[index]
                BarMark(
                    x: .value("Day", Double(index)),
                    y: .value("Amount", value > 0 ? value : stub),
                    width: .ratio(0.55)
                )
                .foregroundStyle(value > 0 ? barColor : Color.white.opacity(0.07))
                .cornerRadius(2.5)
            }

            if let average, average > 0 {
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.white.opacity(0.28))
                    .annotation(position: .trailing, alignment: .center, spacing: 4) {
                        averageLabel(average)
                    }
            }
        }
        .chartXScale(domain: -0.5...(Double(values.count) - 0.5))
        .chartYScale(domain: 0...axisMax)
        .chartXAxis {
            AxisMarks(values: dayLabelIndices) { value in
                AxisValueLabel {
                    if let index = value.as(Double.self).map({ Int($0) }), labels.indices.contains(index) {
                        Text(labels[index])
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, axisMax]) { value in
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(MoneyFormatter.compact(amount))
                            .font(.system(size: 11, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: height)
        .sheet(isPresented: $showAverageInfo) {
            AverageInfoSheet(text: averageExplanation ?? "")
        }
    }

    /// The average value on the right of the rule — just the number, per the
    /// Quanto reference. Tappable when an explanation is provided.
    @ViewBuilder
    private func averageLabel(_ average: Double) -> some View {
        let label = Text(MoneyFormatter.compact(average))
            .font(.system(size: 12, design: .rounded))
            .monospacedDigit()
            .foregroundColor(AppColors.textSecondary)

        if averageExplanation != nil {
            Button {
                Haptics.tap()
                showAverageInfo = true
            } label: {
                label
                    .padding(.vertical, 8)
                    .padding(.horizontal, 3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            label
        }
    }
}

/// Quanto-style "How we calculate the average" bottom sheet: wave-over-dashed
/// glyph, one short paragraph, and a white "Got it" pill.
struct AverageInfoSheet: View {
    let text: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                averageGlyph
                    .padding(.top, AppSpacing.xl)

                Text("How we calculate the average")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: AppSpacing.base)

                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Text("Got it")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
    }

    private var averageGlyph: some View {
        ZStack {
            HorizontalDashLine()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .frame(width: 64, height: 1)
            AverageWave()
                .stroke(style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 64, height: 22)
        }
        .foregroundColor(AppColors.textPrimary)
        .frame(height: 30)
    }
}

/// One soft sine period (the Quanto average glyph).
private struct AverageWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width / 2, y: rect.midY),
            control: CGPoint(x: rect.width / 4, y: -rect.height * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.midY),
            control: CGPoint(x: rect.width * 3 / 4, y: rect.height * 1.4)
        )
        return path
    }
}

struct HorizontalDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        DayBarsChart(
            values: (0..<31).map { $0 == 0 ? 2200 : ($0 == 1 ? 90 : 0) },
            labels: (0..<31).map { [0, 7, 15, 22, 29].contains($0) ? "\($0 + 1)" : "" },
            average: 381,
            averageExplanation: "We add up all transactions in the selected time period and divide it by the number of bars displayed on the chart. Future days are not counted."
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
