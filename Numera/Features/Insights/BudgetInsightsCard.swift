import SwiftUI

/// Premium "Budget left" insight (Quanto Overview anatomy): how much of the
/// overall monthly budget is left for the focused period, plus a history bar
/// chart. Tapping a bar focuses that period within this card only. Shows a
/// "No data" state until an overall budget exists.
struct BudgetInsightsCard: View {
    let period: Period
    let unit: PeriodUnit

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    /// Bar tapped inside this card — scoped here; the rest of the page is unaffected.
    @State private var focus: Period?

    private var activeFocus: Period { focus ?? period }

    private var series: [(period: Period, left: Decimal)] {
        let count = unit == .year ? 5 : 6
        return (0..<count).reversed().map { offset in
            let p = shifted(period, by: -offset)
            return (p, store.budgetRemaining(in: p) ?? 0)
        }
    }

    var body: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        if let left = store.budgetRemaining(in: activeFocus) {
                            MoneyText(
                                amount: left,
                                size: 30,
                                color: left < 0 ? AppColors.expense : AppColors.textPrimary,
                                signed: false
                            )
                        } else {
                            Text("—")
                                .moneyStyle(size: 30, color: AppColors.textTertiary)
                        }
                    }
                    Spacer()
                    if store.overallBudget != nil, focus != nil {
                        periodTag(activeFocus)
                    }
                }

                if store.overallBudget == nil {
                    emptyState
                } else {
                    MonthlyBarsChart(
                        groups: series.map { entry in
                            MonthlyBarGroup(
                                label: PeriodMath.shortLabel(entry.period, unit: unit),
                                primary: max(0, (entry.left as NSDecimalNumber).doubleValue),
                                secondary: 0,
                                isSelected: entry.period == activeFocus
                            )
                        },
                        primaryColor: AppColors.chartTeal,
                        secondaryHidden: true,
                        height: 130,
                        onSelect: { index in
                            withAnimation(.snappy(duration: 0.2)) { focus = series[index].period }
                        }
                    )
                }
            }
        }
        // A new page range clears this card's bar focus.
        .onChange(of: period) { _, _ in focus = nil }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 26, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
            Text("No data")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Text("Set a monthly budget to track what's left.")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }

    private var title: String {
        let noun: String
        switch unit {
        case .week:    noun = "week"
        case .month:   noun = "month"
        case .quarter: noun = "quarter"
        case .year:    noun = "year"
        }
        return activeFocus.contains(.now)
            ? "Budget left this \(noun)"
            : "Budget left in \(PeriodMath.shortLabel(activeFocus, unit: unit))"
    }

    private func periodTag(_ focus: Period) -> some View {
        Text(PeriodMath.shortLabel(focus, unit: unit))
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }

    private func shifted(_ p: Period, by amount: Int) -> Period {
        PeriodMath.shift(
            p,
            by: amount,
            unit: unit,
            startDay: settings.monthStartDay,
            firstWeekday: settings.firstWeekday
        )
    }
}

#Preview {
    ScrollView {
        BudgetInsightsCard(
            period: PeriodMath.period(of: .month, containing: .now, startDay: 1, firstWeekday: 1),
            unit: .month
        )
        .padding()
    }
    .background(AppColors.background)
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
}
