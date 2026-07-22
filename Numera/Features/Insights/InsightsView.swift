import SwiftUI

/// Live analytics for the selected range (weekly / monthly / quarterly /
/// yearly): category donut + breakdown, income vs expenses history, income
/// left, calendar heat grid, cash flow.
struct InsightsView: View {
    let onShowActivity: () -> Void

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(PremiumManager.self) private var premium

    @State private var unit: PeriodUnit = .month
    @State private var pickedPeriod: Period?
    @State private var showMonthPicker = false
    @State private var incomeLeftAsPercent = false
    @State private var showPaywall = false
    @State private var selectedDay: DaySelection?

    /// Category row currently selected (index into `totals`). Single source of
    /// truth for selection: the list highlights exactly this row, and the donut
    /// segment is derived from it via `selectedSegment`.
    @State private var selectedRow: Int?
    /// Period focused by tapping a bar — scoped to its own card, the rest of
    /// the page keeps showing `period`.
    @State private var incomeExpensesFocus: Period?
    @State private var incomeLeftFocus: Period?

    /// Identifiable wrapper so a tapped calendar date can drive `.sheet(item:)`.
    private struct DaySelection: Identifiable {
        let date: Date
        var id: TimeInterval { date.timeIntervalSince1970 }
    }

    private var period: Period {
        if unit == .month { return pickedPeriod ?? store.currentPeriod }
        return PeriodMath.period(
            of: unit,
            containing: .now,
            startDay: settings.monthStartDay,
            firstWeekday: settings.firstWeekday
        )
    }

    private var totals: [CategoryTotal] { store.categoryTotals(in: period) }

    private var series: [(period: Period, income: Decimal, expenses: Decimal)] {
        let count = unit == .year ? 5 : 6
        return (0..<count).reversed().map { offset in
            let p = shifted(period, by: -offset)
            return (p, store.totalIncome(in: p), store.totalExpenses(in: p))
        }
    }

    private var hasData: Bool { !store.transactions(in: period).isEmpty }

    private func shifted(_ p: Period, by amount: Int) -> Period {
        PeriodMath.shift(
            p,
            by: amount,
            unit: unit,
            startDay: settings.monthStartDay,
            firstWeekday: settings.firstWeekday
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        rangePicker

                        summaryDonutCard

                        if hasData {
                            categoryBreakdown
                            incomeVsExpensesCard
                            incomeLeftCard
                            if unit == .month {
                                calendarCard
                            }
                            cashFlowCard
                            highestDayCard
                        } else {
                            emptyState
                        }

                        PremiumGate(
                            isUnlocked: premium.isPremium,
                            title: "RECURRING INSIGHTS",
                            buttonTitle: "Unlock recurring insights"
                        ) { showPaywall = true } content: {
                            RecurringInsightsCard(period: period, unit: unit)
                        }

                        PremiumGate(
                            isUnlocked: premium.isPremium,
                            title: "BUDGETING INSIGHTS",
                            buttonTitle: "Unlock budgeting insights"
                        ) { showPaywall = true } content: {
                            BudgetInsightsCard(period: period, unit: unit)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.xs)
                }
                .refreshable { await store.bootstrap() }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        // A new page range resets the per-card selections.
        .onChange(of: period) { _, _ in
            selectedRow = nil
            incomeExpensesFocus = nil
            incomeLeftFocus = nil
        }
        .onChange(of: unit) { _, _ in
            Haptics.select()
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

    // MARK: - Range picker

    /// Native segmented control (glassy on iOS 26) driving the whole page.
    private var rangePicker: some View {
        Picker("Range", selection: $unit) {
            ForEach(PeriodUnit.allCases) { unit in
                Text(unit.rawValue).tag(unit)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Summary donut

    private var donutSegments: [DonutSegment] {
        // One colored slice per category, using its own picked color — no top-5
        // cap or pooled "Other" slice. Selection is driven by the list, so small
        // slices don't need to be individually tappable on the ring.
        totals.map { DonutSegment(color: Color(hex: $0.category.colorHex), fraction: $0.share) }
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
                                // Each slice maps 1:1 to a category row now.
                                withAnimation(.snappy(duration: 0.2)) { selectedRow = index }
                            }
                        )
                    }

                    Group {
                        if let row = selectedRow, row < totals.count {
                            selectedCategoryCenter(row)
                                .transition(.opacity.combined(with: .scale(scale: 0.94)))
                        } else {
                            defaultDonutCenter
                        }
                    }
                    // Absorb taps in the donut hole (so they can't select a
                    // ring segment) and let a tap clear the selection.
                    .frame(width: 196, height: 196)
                    .contentShape(Circle())
                    .onTapGesture {
                        if selectedRow != nil {
                            withAnimation(.snappy(duration: 0.2)) { selectedRow = nil }
                        }
                    }
                }
                .frame(width: 240, height: 240)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var defaultDonutCenter: some View {
        VStack(spacing: 6) {
            if unit == .month {
                Button { showMonthPicker = true } label: {
                    HStack(spacing: 4) {
                        Text(periodTitle)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            } else {
                Text(periodTitle)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            MoneyText(amount: store.totalExpenses(in: period), size: 34)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            changeBadge
        }
    }

    private var periodTitle: String {
        PeriodMath.title(period, unit: unit)
    }

    /// "No data for this month" / "…for Q1 2026".
    private var periodDescription: String {
        let title = PeriodMath.title(period, unit: unit)
        return title.hasPrefix("This") ? title.lowercased() : title
    }

    /// Donut center for the selected category — always that exact row's spend,
    /// even for small slices the ring pools into "Other". The amount scales to a
    /// single line so large values don't wrap inside the donut hole.
    private func selectedCategoryCenter(_ row: Int) -> some View {
        let item = totals[row]
        return VStack(spacing: 5) {
            Text(item.category.emoji)
                .font(.system(size: 26, design: .rounded))
            Text(item.category.name)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
            MoneyText(amount: item.total, size: 30)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("\(Int((item.share * 100).rounded()))% of spending")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    @ViewBuilder
    private var changeBadge: some View {
        let previous = shifted(period, by: -1)
        let previousTotal = store.totalExpenses(in: previous)
        if previousTotal > 0 {
            let change = (((store.totalExpenses(in: period) - previousTotal) / previousTotal * 100) as NSDecimalNumber).doubleValue
            let isDown = change <= 0
            let previousLabel = unit == .week ? "last week" : PeriodMath.shortLabel(previous, unit: unit)
            HStack(spacing: 4) {
                Image(systemName: isDown ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 13, design: .rounded))
                Text("\(abs(Int(change.rounded())))% from \(previousLabel)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isDown ? AppColors.accent : AppColors.expense)
        }
    }

    // MARK: - Category breakdown

    /// Donut segment highlighted for the current selection. Each category maps
    /// 1:1 to its own slice, so the highlighted segment is just the selected
    /// row. Read-only — `selectedRow` is the source of truth.
    private var selectedSegment: Int? {
        guard let row = selectedRow, row < donutSegments.count else { return nil }
        return row
    }

    private func toggleRow(_ row: Int) {
        selectedRow = (selectedRow == row) ? nil : row
    }

    private var categoryBreakdown: some View {
        SettingsCard {
            ForEach(Array(totals.enumerated()), id: \.element.id) { index, item in
                let isSelected = selectedRow == index
                Button {
                    Haptics.select()
                    withAnimation(.snappy(duration: 0.2)) { toggleRow(index) }
                } label: {
                    HStack(spacing: AppSpacing.base) {
                        EmojiIconTile(emoji: item.category.emoji, colorHex: item.category.colorHex, size: 44)

                        Text(item.category.name)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)

                        Text("\(item.count)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())

                        Spacer()

                        MoneyText(amount: item.total, size: 15)

                        Text("\(Int((item.share * 100).rounded()))%")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, AppSpacing.base)
                    .padding(.vertical, AppSpacing.md)
                    .background(isSelected ? Color.white.opacity(0.05) : Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < totals.count - 1 {
                    Divider().background(AppColors.borderSubtle).padding(.leading, 76)
                }
            }
        }
    }

    // MARK: - Income vs expenses

    private var incomeVsExpensesCard: some View {
        // Tapping a bar focuses that period within THIS card only — the legend
        // above follows it; the rest of the page stays on `period`.
        let focus = incomeExpensesFocus ?? period
        return NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    legendValue(color: AppColors.income, label: "Income", amount: store.totalIncome(in: focus))
                    legendValue(color: AppColors.chartPurple, label: "Expenses", amount: store.totalExpenses(in: focus))
                    Spacer()
                    periodTag(focus)
                }

                MonthlyBarsChart(
                    groups: series.map { entry in
                        MonthlyBarGroup(
                            label: PeriodMath.shortLabel(entry.period, unit: unit),
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

    /// Small capsule naming the period a card's numbers refer to.
    private func periodTag(_ focus: Period) -> some View {
        Text(PeriodMath.shortLabel(focus, unit: unit))
            .font(.system(size: 13, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 13, design: .rounded))
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
                        Text(incomeLeftTitle(for: focus))
                            .font(.system(size: 15, design: .rounded))
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
                            label: PeriodMath.shortLabel(entry.period, unit: unit),
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

    private func incomeLeftTitle(for focus: Period) -> String {
        let noun: String
        switch unit {
        case .week:    noun = "week"
        case .month:   noun = "month"
        case .quarter: noun = "quarter"
        case .year:    noun = "year"
        }
        return focus.contains(.now)
            ? "Income left this \(noun)"
            : "Income left in \(PeriodMath.shortLabel(focus, unit: unit))"
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
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isActive ? .black : AppColors.textSecondary)
                .frame(width: 42, height: 32)
                .background(isActive ? AppColors.accent : Color.clear)
                .clipShape(Capsule())
        }
    }

    // MARK: - Calendar

    /// Solid (non-glass) container: the day cells inside are Liquid Glass, and
    /// glass must not stack on glass.
    private var calendarCard: some View {
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
        .padding(AppSpacing.base)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                .fill(AppColors.surfaceCard.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        )
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
                        .font(.system(size: 12, design: .rounded))
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
                        .font(.system(size: 14, design: .rounded))
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
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                        if let topName = topCategoryName(on: highest.date) {
                            Text("Mostly \(topName)")
                                .font(.system(size: 13, design: .rounded))
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
        fmt.dateFormat = unit == .year ? "EEEE, MMM d yyyy" : "EEEE, MMM d"
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
                    .font(.system(size: 34, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                Text("No data for \(periodDescription)")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("Add transactions and your analytics will build themselves.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button { onShowActivity() } label: {
                    Text("Go to Activity")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
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
