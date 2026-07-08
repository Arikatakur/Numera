import SwiftUI
import Charts

struct MonthlyBarGroup: Identifiable {
    let id = UUID()
    let label: String
    let primary: Double
    let secondary: Double
    var isSelected: Bool = false
}

/// Paired rounded bars per period (income vs expenses) on native Swift Charts,
/// with tappable period labels — Quanto Overview chart. Pass `secondaryHidden`
/// for single-series.
struct MonthlyBarsChart: View {
    let groups: [MonthlyBarGroup]
    var primaryColor: Color = AppColors.accent
    var secondaryColor: Color = AppColors.chartPurple
    var secondaryHidden: Bool = false
    var height: CGFloat = 150
    var onSelect: ((Int) -> Void)?

    private var maxValue: Double {
        let all = groups.flatMap { secondaryHidden ? [$0.primary] : [$0.primary, $0.secondary] }
        return max(all.max() ?? 0, 1)
    }

    /// Empty periods keep a small stub so the baseline stays readable.
    private var stub: Double { maxValue * 0.045 }

    var body: some View {
        Chart {
            ForEach(groups) { group in
                if secondaryHidden {
                    bar(group.label, group.primary, primaryColor, series: "Amount")
                } else {
                    bar(group.label, group.primary, primaryColor, series: "Income")
                        .position(by: .value("Series", "Income"))
                    bar(group.label, group.secondary, secondaryColor, series: "Expenses")
                        .position(by: .value("Series", "Expenses"))
                }
            }
        }
        // Keep the data's order — Swift Charts sorts string categories otherwise.
        .chartXScale(domain: groups.map(\.label))
        .chartYScale(domain: 0...(maxValue * 1.05))
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        periodLabel(label)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        // A plain tap that maps to the nearest period is far more reliable than
        // chartXSelection (which wants a scrub) — every bar, wide or narrow,
        // selects on a single tap.
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        guard let anchor = proxy.plotFrame else { return }
                        let plot = geo[anchor]
                        guard let label = proxy.value(atX: location.x - plot.minX, as: String.self),
                              let index = groups.firstIndex(where: { $0.label == label }) else { return }
                        Haptics.select()
                        onSelect?(index)
                    }
            }
        }
        .frame(height: height + 30)
    }

    private func bar(_ label: String, _ value: Double, _ color: Color, series: String) -> some ChartContent {
        BarMark(
            x: .value("Period", label),
            y: .value(series, value > 0 ? value : stub),
            width: .fixed(13)
        )
        .foregroundStyle(value > 0 ? color : Color.white.opacity(0.08))
        .cornerRadius(3)
    }

    /// Quanto-style axis label: the selected period wears a soft capsule.
    private func periodLabel(_ label: String) -> some View {
        let isSelected = groups.first(where: { $0.label == label })?.isSelected == true
        return Text(label)
            .font(.system(size: 12, weight: isSelected ? .semibold : .regular, design: .rounded))
            .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textTertiary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(isSelected ? Color.white.opacity(0.09) : Color.clear, in: Capsule())
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        MonthlyBarsChart(
            groups: [
                MonthlyBarGroup(label: "Feb", primary: 0, secondary: 0),
                MonthlyBarGroup(label: "Mar", primary: 900, secondary: 400),
                MonthlyBarGroup(label: "Apr", primary: 1200, secondary: 800),
                MonthlyBarGroup(label: "May", primary: 700, secondary: 950),
                MonthlyBarGroup(label: "Jun", primary: 1600, secondary: 620),
                MonthlyBarGroup(label: "Jul", primary: 1100, secondary: 300, isSelected: true),
            ],
            primaryColor: AppColors.income,
            secondaryColor: AppColors.chartPurple
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
