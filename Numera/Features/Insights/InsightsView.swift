import SwiftUI

/// Live analytics for the selected period: category donut + breakdown,
/// income vs expenses history, income left, calendar heat grid, cash flow.
struct InsightsView: View {
    let onShowActivity: () -> Void

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(PremiumManager.self) private var premium

    @State private var pickedPeriod: Period?
    @State private var showMonthPicker = false
    @State private var incomeLeftAsPercent = false
    @State private var showPaywall = false
    @State private var selectedDay: DaySelection?

    /// Donut segment picked by tapping the ring (index into `donutSegments`).
    @State private var selectedSegment: Int?
    /// Month focused by tapping a bar — scoped to its own card, the rest of
    /// the page keeps showing `period`.
    @State private var incomeExpensesFocus: Period?
    @State private var incomeLeftFocus: Period?

    /// Identifiable wrapper so a tapped calendar date can drive `.sheet(item:)`.
    private struct DaySelection: Identifiable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSince1970 }
    }

    private var period: Period { pickedPeriod ?? store.currentPeriod }
    private var totals: [CategoryTotal] { store.categoryTotals(in: period) }
    private var series: [(period: Period, income: Decimal, expenses: Decimal)] {
        store.monthlySeries(endingAt: period, count: 6)
    }
    private var hasData: Bool { !store.transactions(in: period).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        PageTitle(text: "Insights")

                        summaryDonutCard

                        if hasData {
                            categoryBreakdown
                            incomeVsExpensesCard
                            incomeLeftCard
                            calendarCard
                            cashFlowCard
                            highestDayCard
                        } else {
                            emptyState
                        }

                        if !premium.isPremium {
                            PremiumLockCard(
                                title: "RECURRING INSIGHTS",
                                buttonTitle: "Unlock recurring insights"
                            ) { showPaywall = true }

                            PremiumLockCard(
                                title: "BUDGETING INSIGHTS",
                                buttonTitle: "Unlock budgeting insights",
                                height: 170
                            ) { showPaywall = true }
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.sm)
                }
                .refreshable { await store.bootstrap() }
            }
            .navigationBarHidden(true)
        }
        // A new page month resets the per-card selections.
        .onChange(of: period) { _, _ in
            selectedSegment = nil
            incomeExpensesFocus = nil
            incomeLeftFocus = nil
        }
        .sheet(isPresented: $showMonthPicker) {
            SelectMonthSheet(
                period: Binding(get: { period }, set: { pickedPeriod = $0 }),
                startDay: settings.monthStartDay,
                earliest: store.transactions.last?.date
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: $selectedDay) { selection in
            DayTransactionsSheet(date: selection.date)
        }
    }

    // MARK: - Summary donut

    private var donutSegments: [DonutSegment] {
        let top = totals.prefix(5)
        var segments = top.map { DonutSegment(color: Color(hex: $0.category.colorHex), fraction: $0.share) }
        let remainder = totals.dropFirst(5).reduce(0.0) { $0 + $1.share }
        if remainder > 0.01 {
            segments.append(DonutSegment(color: AppColors.textTertiary.opacity(0.5), fraction: remainder))
        }
        return segments
    }

    private var summaryDonutCard: some View {
        NumeraCard {
            VStack(spacing: AppSpacing.base) {
                ZStack {
                    if donutSegments.isEmpty {
                        Circle().stroke(AppColors.surfaceHigh.opacity(0.6), lineWidth: 18)
                    } else {
                        DonutChart(
                            segments: donutSegments,
                            lineWidth: 18,
                            selectedIndex: selectedSegment,
                            onSelectSegment: { index in
                                withAnimation(.snappy(duration: 0.2)) { selectedSegment = index }
                            }
                        )
                    }

                    if let selected = selectedSegment, selected < donutSegments.count {
                        selectedSegmentCenter(selected)
                            .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    } else {
                        VStack(spacing: 6) {
                            Button { showMonthPicker = true } label: {
                                HStack(spacing: 4) {
                                    Text(monthTitle)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppColors.textSecondary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                            MoneyText(amount: store.totalExpenses(in: period), size: 34)
                            changeBadge
                        }
                    }
                }
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthTitle: String {
        period == store.currentPeriod ? "This month" : PeriodMath.monthLabel(period)
    }

    /// Donut center while a ring segment is selected: that category's spend.
    /// Segments are `totals.prefix(5)` plus an optional "other" remainder.
    private func selectedSegmentCenter(_ index: Int) -> some View {
        let top = Array(totals.prefix(5))
        return VStack(spacing: 5) {
            if index < top.count {
                let item = top[index]
                Text(item.category.emoji)
                    .font(.system(size: 26))
                Text(item.category.name)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                MoneyText(amount: item.total, size: 30)
                Text("\(Int((item.share * 100).rounded()))% of spending")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            } else {
                let rest = totals.dropFirst(5)
                Text("Other")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                MoneyText(amount: rest.reduce(Decimal(0)) { $0 + $1.total }, size: 30)
                Text("\(Int((rest.reduce(0.0) { $0 + $1.share } * 100).rounded()))% of spending")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.xxl)
    }

    @ViewBuilder
    private var changeBadge: some View {
        if let change = store.expenseChange(in: period) {
            let isDown = change <= 0
            let previousLabel = PeriodMath.shortLabel(store.shiftPeriod(period, by: -1))
            HStack(spacing: 4) {
                Image(systemName: isDown ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 13))
                Text("\(abs(Int(change.rounded())))% from \(previousLabel)")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isDown ? AppColors.accent : AppColors.expense)
        }
    }

    // MARK: - Category breakdown

    private var categoryBreakdown: some View {
        SettingsCard {
            ForEach(Array(totals.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: AppSpacing.base) {
                    EmojiIconTile(emoji: item.category.emoji, colorHex: item.category.colorHex, size: 44)

                    Text(item.category.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    Text("\(item.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())

                    Spacer()

                    MoneyText(amount: item.total, size: 15)

                    Text("\(Int((item.share * 100).rounded()))%")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.md)

                if index < totals.count - 1 {
                    Divider().background(AppColors.borderSubtle).padding(.leading, 76)
                }
            }
        }
    }

    // MARK: - Income vs expenses

    private var incomeVsExpensesCard: some View {
        // Tapping a bar focuses that month within THIS card only — the legend
        // above follows it; the rest of the page stays on `period`.
        let focus = incomeExpensesFocus ?? period
        return NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    legendValue(color: AppColors.income, label: "Income", amount: store.totalIncome(in: focus))
                    legendValue(color: AppColors.chartPurple, label: "Expenses", amount: store.totalExpenses(in: focus))
                    Spacer()
                    monthTag(focus)
                }

                MonthlyBarsChart(
                    groups: series.map { entry in
                        MonthlyBarGroup(
                            label: PeriodMath.shortLabel(entry.period),
                            primary: (entry.income as NSDecimalNumber).doubleValue,
                            secondary: (entry.expenses as NSDecimalNumber).doubleValue,
                            isSelected: entry.period == focus
                        )
                    },
                    primaryColor: AppColors.income,
                    secondaryColor: AppColors.chartPurple,
                    onSelect: { index in
                        withAnimation(.snappy(duration: 0.2)) { incomeExpensesFocus = series[index].period }
                    }
                )
            }
        }
    }

    /// Small capsule naming the month a card's numbers refer to.
    private func monthTag(_ focus: Period) -> some View {
        Text(PeriodMath.shortLabel(focus))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }

    private func legendValue(color: Color, label: String, amount: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            MoneyText(amount: amount, size: 18)
        }
    }

    // MARK: - Income left

    private var incomeLeftCard: some View {
        // Same per-card focus as income vs expenses: bar taps stay local.
        let focus = incomeLeftFocus ?? period
        let net = store.net(in: focus)
        let income = store.totalIncome(in: focus)
        return NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(focus == store.currentPeriod
                             ? "Income left this month"
                             : "Income left in \(PeriodMath.shortLabel(focus))")
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                        if incomeLeftAsPercent {
                            Text(percentLeftText(net: net, income: income))
                                .moneyStyle(size: 30, color: AppColors.textPrimary)
                        } else {
                            MoneyText(amount: net, size: 30, color: AppColors.textPrimary)
                        }
                    }
                    Spacer()
                    dollarPercentToggle
                }

                MonthlyBarsChart(
                    groups: series.map { entry in
                        let leftover = (entry.income - entry.expenses) as NSDecimalNumber
                        return MonthlyBarGroup(
                            label: PeriodMath.shortLabel(entry.period),
                            primary: max(0, leftover.doubleValue),
                            secondary: 0,
                            isSelected: entry.period == focus
                        )
                    },
                    primaryColor: AppColors.chartTeal,
                    secondaryHidden: true,
                    height: 110,
                    onSelect: { index in
                        withAnimation(.snappy(duration: 0.2)) { incomeLeftFocus = series[index].period }
                    }
                )
            }
        }
    }

    /// Share of income still unspent; overspending never shows a negative —
    /// it clamps to 0%.
    private func percentLeftText(net: Decimal, income: Decimal) -> String {
        guard income > 0 else { return "0%" }
        let percent = max(0, ((net / income * 100) as NSDecimalNumber).doubleValue)
        return "\(Int(percent.rounded()))%"
    }

    private var dollarPercentToggle: some View {
        HStack(spacing: 0) {
            toggleSegment(symbol: settings.currencySymbol, isActive: !incomeLeftAsPercent) {
                incomeLeftAsPercent = false
            }
            toggleSegment(symbol: "%", isActive: incomeLeftAsPercent) {
                incomeLeftAsPercent = true
            }
        }
        .background(AppColors.surfaceElevated)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
    }

    private func toggleSegment(symbol: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.select()
            action()
        } label: {
            Text(symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isActive ? .black : AppColors.textSecondary)
                .frame(width: 42, height: 32)
                .background(isActive ? AppColors.accent : Color.clear)
                .clipShape(Capsule())
        }
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        NumeraCard(padding: AppSpacing.base) {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("CALENDAR")
                    .labelCapsStyle()
                    .padding(.top, AppSpacing.xs)

                CalendarSpendGrid(
                    period: period,
                    totals: Dictionary(uniqueKeysWithValues: store.dailyTotals(in: period).map { ($0.date, $0.total) }),
                    firstWeekday: settings.firstWeekday,
                    onSelectDay: { selectedDay = DaySelection(date: $0) }
                )
            }
        }
    }

    // MARK: - Cash flow

    private var cashFlowCard: some View {
        let income = store.totalIncome(in: period)
        let expenses = store.totalExpenses(in: period)
        let net = income - expenses
        let incomeValue = (income as NSDecimalNumber).doubleValue
        let expenseFill = incomeValue > 0
            ? min(1, (expenses as NSDecimalNumber).doubleValue / incomeValue)
            : (expenses > 0 ? 1 : 0)

        return NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("CASH FLOW")
                    .labelCapsStyle()

                cashFlowRow(label: "Income", amount: income, color: AppColors.income, fill: income > 0 ? 1 : 0, signed: true)
                cashFlowRow(label: "Expenses", amount: -expenses, color: AppColors.chartPurple, fill: expenseFill, signed: false)

                Divider().background(AppColors.borderGlass)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NET")
                            .labelCapsStyle()
                        MoneyText(amount: net, size: 22, color: net < 0 ? AppColors.expense : AppColors.textPrimary, signed: true)
                    }
                    Spacer()
                    Text("Income − expenses")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
    }

    private func cashFlowRow(label: String, amount: Decimal, color: Color, fill: Double, signed: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 7, height: 7)
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                MoneyText(amount: amount, size: 14, color: color, signed: signed)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.surfaceHigh).frame(height: 6)
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(fill), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Highest day

    @ViewBuilder
    private var highestDayCard: some View {
        if let highest = store.highestSpendingDay(in: period) {
            NumeraCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HIGHEST SPENDING DAY")
                            .labelCapsStyle()
                        Text(fullDayLabel(highest.date))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        if let topName = topCategoryName(on: highest.date) {
                            Text("Mostly \(topName)")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    MoneyText(amount: highest.total, size: 20)
                }
            }
        }
    }

    private func fullDayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date)
    }

    private func topCategoryName(on day: Date) -> String? {
        let calendar = Calendar.current
        let dayTransactions = store.transactions(in: period).filter {
            $0.type == .expense && calendar.isDate($0.date, inSameDayAs: day)
        }
        let byCategory = Dictionary(grouping: dayTransactions) { $0.categoryId }
        let top = byCategory.max { lhs, rhs in
            lhs.value.reduce(Decimal(0)) { $0 + $1.amount } < rhs.value.reduce(Decimal(0)) { $0 + $1.amount }
        }
        return top.flatMap { store.category($0.key)?.name }
    }

    // MARK: - Empty

    private var emptyState: some View {
        NumeraCard {
            VStack(spacing: AppSpacing.base) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 34))
                    .foregroundColor(AppColors.textTertiary)
                Text("No data for \(PeriodMath.monthLabel(period))")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Add transactions and your analytics will build themselves.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button { onShowActivity() } label: {
                    Text("Go to Activity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
    }
}

#Preview {
    InsightsView(onShowActivity: {})
        .preferredColorScheme(.dark)
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
        .environment(PremiumManager.preview())
}
