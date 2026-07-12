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

    @Environment(AppSettings.self) private var settings: AppSettings?

    private var maxValue: Double { max(values.max() ?? 0, 1) }

    // MARK: - Outlier-aware Y scale
    //
    // A single large day (e.g. Rent) used to set the axis to its own value, which
    // crushed every normal day into an unreadable stub at the bottom. Instead the
    // axis is scaled to *normal* spending and any day above the ceiling is drawn
    // clipped to the top, then flagged with an up-marker and its exact amount (see
    // `outlierCallout`). Nothing is silently capped — the true value is always
    // shown. Rationale: scale to the chart's job (comparing normal days) + label
    // the outlier, per data-viz guidance (avoids misleading log/broken axes).

    /// Positive daily totals only — zero days are "no activity", not part of the
    /// normal-spending distribution used to judge outliers.
    private var positives: [Double] { values.filter { $0 > 0 } }

    /// Tukey upper fence (Q3 + 1.5·IQR) over the positive days: the boundary above
    /// which a day is an extreme outlier. `.infinity` when there are too few days
    /// to judge, so nothing is treated as an outlier (chart behaves as before).
    private var outlierFence: Double {
        let p = positives.sorted()
        guard p.count >= 4 else { return .infinity }
        func quantile(_ q: Double) -> Double {
            let pos = q * Double(p.count - 1)
            let lo = Int(pos.rounded(.down))
            let hi = Int(pos.rounded(.up))
            if lo == hi { return p[lo] }
            return p[lo] + (p[hi] - p[lo]) * (pos - Double(lo))
        }
        let q1 = quantile(0.25)
        let q3 = quantile(0.75)
        return q3 + 1.5 * (q3 - q1)
    }

    /// Largest "normal" day (outliers excluded). Falls back to the plain max when
    /// there are no outliers or too few points.
    private var normalMax: Double {
        let fence = outlierFence
        let normals = positives.filter { $0 <= fence }
        return normals.max() ?? maxValue
    }

    /// Axis ceiling: scaled to normal spending, but always tall enough to keep the
    /// average line on-chart. Rounded up to 1 / 2 / 2.5 / 5 × 10ⁿ so the top label
    /// reads clean ("500", not "2,286.71"). With no outlier this equals the old
    /// `niceCeil(max)`, so nothing changes for well-behaved data.
    private var axisMax: Double {
        niceCeil(max(normalMax, average ?? 0, 1))
    }

    private func niceCeil(_ value: Double) -> Double {
        let v = max(value, 1)
        let exponent = floor(log10(v))
        let base = pow(10.0, exponent)
        let mantissa = v / base
        let nice: Double = mantissa <= 1 ? 1 : mantissa <= 2 ? 2 : mantissa <= 2.5 ? 2.5 : mantissa <= 5 ? 5 : 10
        return nice * base
    }

    /// Days taller than the ceiling — drawn clipped to the top and flagged with a
    /// marker + exact value. The 0.5 epsilon avoids float-noise false positives.
    private var outlierIndices: [Int] {
        values.indices.filter { values[$0] > axisMax + 0.5 }
    }

    /// Empty days keep a tiny stub so the baseline reads as a row of dots.
    private var stub: Double { axisMax * 0.018 }

    /// Categorical keys ("0","1",…). A numeric x-scale with `.ratio` bar width
    /// rendered the thin day bars invisibly; a category scale + fixed width
    /// (matching MonthlyBarsChart, which works) draws them reliably.
    private var dayKeys: [String] { values.indices.map(String.init) }

    /// Only the marked days (non-empty label) get an axis tick.
    private var markedKeys: [String] {
        labels.indices.filter { !labels[$0].isEmpty }.map(String.init)
    }

    var body: some View {
        Chart {
            ForEach(values.indices, id: \.self) { index in
                let value = values[index]
                BarMark(
                    x: .value("Day", dayKeys[index]),
                    y: .value("Amount", value > 0 ? min(value, axisMax) : stub),
                    width: .fixed(5)
                )
                .foregroundStyle(value > 0 ? barColor : Color.white.opacity(0.07))
                .cornerRadius(2)
            }

            if let average, average > 0 {
                RuleMark(y: .value("Average", average))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.white.opacity(0.28))
            }
        }
        .chartXScale(domain: dayKeys)
        .chartYScale(domain: 0...axisMax)
        .chartXAxis {
            AxisMarks(values: markedKeys) { value in
                AxisValueLabel {
                    if let key = value.as(String.self), let index = Int(key), labels.indices.contains(index) {
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
        // The average number, positioned on the rule via the plot proxy so it's
        // reliably tappable (a RuleMark annotation clipped its own hit area).
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let average, average > 0, averageExplanation != nil,
                   let anchor = proxy.plotFrame, let y = proxy.position(forY: average) {
                    let plot = geo[anchor]
                    Button {
                        Haptics.tap()
                        showAverageInfo = true
                    } label: {
                        Text(MoneyFormatter.compact(average))
                            .font(.system(size: 12, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 7)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: plot.maxX - 2, y: plot.minY + y)
                }
            }
        }
        // Outlier callouts: any day taller than the axis (drawn clipped to the top)
        // is flagged here with an up-marker and its exact amount, so the real value
        // is never hidden. Positioned on the plot via the proxy, like the average.
        .chartOverlay { proxy in
            GeometryReader { geo in
                if let anchor = proxy.plotFrame {
                    let plot = geo[anchor]
                    ForEach(outlierIndices, id: \.self) { index in
                        if let x = proxy.position(forX: dayKeys[index]) {
                            outlierCallout(value: values[index])
                                .position(x: plot.minX + x, y: plot.minY + 16)
                        }
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

    /// The marker for a clipped (outlier) bar: an up-triangle over a small pill with
    /// the day's exact amount. Non-interactive so it never blocks taps underneath.
    private func outlierCallout(value: Double) -> some View {
        VStack(spacing: 1) {
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(barColor)
            Text(MoneyFormatter.string(
                Decimal(value),
                code: settings?.currencyCode ?? "USD",
                cents: settings?.displayCents ?? false
            ))
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(AppColors.textPrimary)
            .fixedSize()
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(AppColors.background.opacity(0.85), in: Capsule())
            .overlay(Capsule().stroke(barColor.opacity(0.45), lineWidth: 1))
        }
        .allowsHitTesting(false)
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
            // Day 1 is a Rent-sized outlier; the rest are normal days. The axis
            // scales to the normal range and the outlier is clipped + labeled.
            values: (0..<31).map { i in
                switch i {
                case 0:  return 4000   // Rent — outlier
                case 2:  return 380
                case 4:  return 128
                case 6:  return 64
                case 8:  return 90
                case 10: return 50
                case 13: return 220
                case 15: return 32
                default: return 0
                }
            },
            labels: (0..<31).map { [0, 7, 15, 22, 29].contains($0) ? "\($0 + 1)" : "" },
            average: 300,
            averageExplanation: "We add up all transactions in the selected time period and divide it by the number of bars displayed on the chart. Future days are not counted."
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
