import SwiftUI

/// Quanto-style activity: month hero with day bars, filter chips, and a
/// day-grouped list with per-day totals. Tap a row to edit it.
struct ActivityView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    enum TypeFilter: String, CaseIterable, Identifiable {
        case expenses = "Expenses"
        case income = "Income"
        case all = "All"
        var id: String { rawValue }
    }

    @State private var pickedPeriod: Period?
    @State private var showMonthPicker = false
    @State private var typeFilter: TypeFilter = .expenses
    @State private var accountFilter: UUID?
    @State private var categoryFilter: UUID?
    @State private var searchActive = false
    @State private var searchText = ""
    @State private var editingTransaction: Transaction?

    private var period: Period { pickedPeriod ?? store.currentPeriod }

    /// The type driving the hero total, chart, and group totals.
    private var focusType: TransactionType { typeFilter == .income ? .income : .expense }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        heroSection
                        chipsSection
                        if searchActive { searchField }
                        listSection
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .refreshable { await store.bootstrap() }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showMonthPicker) {
            SelectMonthSheet(
                period: Binding(get: { period }, set: { pickedPeriod = $0 }),
                startDay: settings.monthStartDay,
                earliest: store.transactions.last?.date
            )
        }
        .sheet(item: $editingTransaction) { tx in
            AddTransactionView(editing: tx)
        }
    }

    // MARK: - Filtering

    private var filtered: [Transaction] {
        store.transactions(in: period).filter { tx in
            let matchesType: Bool = {
                switch typeFilter {
                case .expenses: return tx.type == .expense
                case .income:   return tx.type == .income
                case .all:      return true
                }
            }()
            let matchesAccount = accountFilter == nil || tx.accountId == accountFilter
            let matchesCategory = categoryFilter == nil || tx.categoryId == categoryFilter
            let matchesSearch = searchText.isEmpty
                || tx.title.localizedCaseInsensitiveContains(searchText)
                || (tx.note ?? "").localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesAccount && matchesCategory && matchesSearch
        }
    }

    private var focusTotal: Decimal {
        filtered.filter { $0.type == focusType }.reduce(0) { $0 + $1.amount }
    }

    private var grouped: [(day: Date, label: String, total: Decimal, txs: [Transaction])] {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: filtered) { calendar.startOfDay(for: $0.date) }
        return byDay.keys.sorted(by: >).map { day in
            let txs = (byDay[day] ?? []).sorted { $0.date > $1.date }
            let total = txs.filter { $0.type == focusType }.reduce(Decimal(0)) { $0 + $1.amount }
            return (day, dayLabel(day), total, txs)
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMM"
        return fmt.string(from: day)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: AppSpacing.md) {
            Button { showMonthPicker = true } label: {
                HStack(spacing: 5) {
                    Text(PeriodMath.monthLabel(period))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .frame(height: 36)

            MoneyText(amount: focusTotal, size: 44)

            chart
                .padding(.horizontal, AppSpacing.screenMargin)
        }
    }

    private var chartValues: [Double] {
        let calendar = Calendar.current
        let relevant = filtered.filter { $0.type == focusType }
        let byDay = Dictionary(grouping: relevant) { calendar.startOfDay(for: $0.date) }
        return PeriodMath.days(in: period).map { day in
            let total = byDay[day]?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0
            return (total as NSDecimalNumber).doubleValue
        }
    }

    private var chartAverage: Double? {
        let total = chartValues.reduce(0, +)
        guard total > 0 else { return nil }
        let calendar = Calendar.current
        let elapsed: Int
        if period.contains(.now) {
            let days = calendar.dateComponents([.day], from: period.start, to: calendar.startOfDay(for: .now)).day ?? 0
            elapsed = max(1, days + 1)
        } else {
            elapsed = max(1, period.dayCount)
        }
        return total / Double(elapsed)
    }

    private var chartLabels: [String] {
        let days = PeriodMath.days(in: period)
        let marks: Set<Int> = [0, 7, 15, 22, 29]
        return days.enumerated().map { index, day in
            marks.contains(index) ? "\(Calendar.current.component(.day, from: day))" : ""
        }
    }

    @ViewBuilder
    private var chart: some View {
        if filtered.isEmpty && searchText.isEmpty {
            EmptyView()
        } else {
            DayBarsChart(
                values: chartValues,
                labels: chartLabels,
                average: chartAverage,
                averageExplanation: "Daily average: this month's total \(typeFilter == .income ? "income" : "spending") divided by the days elapsed so far. Past months divide by all their days.",
                barColor: typeFilter == .income ? AppColors.income : AppColors.accent,
                height: 150
            )
        }
    }

    // MARK: - Chips

    private var chipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // Adjacent glass chips share one container so their glass blends
            // (Apple's GlassEffectContainer) instead of stacking.
            LiquidGlassGroup(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Button {
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.2)) {
                        searchActive.toggle()
                        if !searchActive { searchText = "" }
                    }
                } label: {
                    let icon = Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(searchActive ? .black : AppColors.textPrimary)
                        .frame(width: 38, height: 38)
                    if searchActive {
                        icon.background(AppColors.accent, in: Circle())
                    } else {
                        icon.liquidGlassControl(Circle(), fallbackFill: AppColors.surfaceElevated)
                    }
                }

                Menu {
                    ForEach(TypeFilter.allCases) { filter in
                        Button {
                            typeFilter = filter
                        } label: {
                            if typeFilter == filter {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                } label: {
                    filterChip(typeFilter.rawValue, highlighted: typeFilter != .all)
                }

                Menu {
                    Button("All accounts") { accountFilter = nil }
                    ForEach(store.accounts) { account in
                        Button("\(account.emoji) \(account.name)") { accountFilter = account.id }
                    }
                } label: {
                    filterChip(
                        accountFilter.flatMap { store.account($0)?.name } ?? "All accounts",
                        highlighted: accountFilter != nil
                    )
                }

                Menu {
                    Button("All categories") { categoryFilter = nil }
                    ForEach(store.categories(of: .expense)) { category in
                        Button("\(category.emoji) \(category.name)") { categoryFilter = category.id }
                    }
                    ForEach(store.categories(of: .income)) { category in
                        Button("\(category.emoji) \(category.name)") { categoryFilter = category.id }
                    }
                } label: {
                    filterChip(
                        categoryFilter.flatMap { store.category($0)?.name } ?? "All categories",
                        highlighted: categoryFilter != nil
                    )
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            }
        }
    }

    private func filterChip(_ label: String, highlighted: Bool) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(AppColors.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassControl(Capsule(), fallbackFill: AppColors.surfaceElevated)
        .overlay(
            Capsule().stroke(highlighted ? AppColors.accent.opacity(0.6) : Color.clear, lineWidth: 1)
        )
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 15))
            TextField("Search transactions", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.accent)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, 12)
        .liquidGlassControl(Capsule(), fallbackFill: AppColors.surfaceCard)
        .padding(.horizontal, AppSpacing.screenMargin)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - List

    @ViewBuilder
    private var listSection: some View {
        if grouped.isEmpty {
            VStack(spacing: AppSpacing.base) {
                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(AppColors.textTertiary)
                Text(searchText.isEmpty ? "Nothing here yet" : "No results")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                if searchText.isEmpty {
                    Text("Tap + to add a transaction for \(PeriodMath.monthLabel(period)).")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.xxl)
        } else {
            VStack(spacing: AppSpacing.lg) {
                ForEach(grouped, id: \.day) { group in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text(group.label)
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            if group.total > 0 {
                                MoneyText(amount: group.total, size: 15, color: AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, AppSpacing.xs)

                        SettingsCard {
                            ForEach(Array(group.txs.enumerated()), id: \.element.id) { index, tx in
                                Button {
                                    editingTransaction = tx
                                } label: {
                                    TransactionRow(transaction: tx, showsDate: false)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task { await store.deleteTransaction(id: tx.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                if index < group.txs.count - 1 {
                                    Divider()
                                        .background(AppColors.borderSubtle)
                                        .padding(.leading, 78)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
        }
    }
}

#Preview {
    ActivityView()
        .preferredColorScheme(.dark)
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
}
