import SwiftUI

struct ActivityView: View {
    @Environment(TransactionStore.self) private var store
    @Environment(AppSettings.self)    private var settings

    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var showAddTransaction = false

    private let filters = ["All", "Expenses", "Income", "Recurring"]

    private var filtered: [Transaction] {
        store.transactions.filter { tx in
            let matchFilter: Bool = {
                switch selectedFilter {
                case "Expenses": return tx.type == .expense
                case "Income":   return tx.type == .income
                default:         return true
                }
            }()
            let matchSearch = searchText.isEmpty || tx.title.localizedCaseInsensitiveContains(searchText)
            return matchFilter && matchSearch
        }
    }

    private var grouped: [(String, [Transaction])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { tx -> String in
            if cal.isDateInToday(tx.date)     { return "TODAY" }
            if cal.isDateInYesterday(tx.date) { return "YESTERDAY" }
            let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
            return fmt.string(from: tx.date).uppercased()
        }
        return dict.sorted { lhs, rhs in
            // Sort so TODAY > YESTERDAY > older dates
            let order = ["TODAY": 0, "YESTERDAY": 1]
            let l = order[lhs.key] ?? 2
            let r = order[rhs.key] ?? 2
            if l != r { return l < r }
            return lhs.key > rhs.key
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.base)

                    filterChips
                        .padding(.top, AppSpacing.base)

                    transactionList
                }

                FloatingAddButton { showAddTransaction = true }
                    .padding(.trailing, AppSpacing.screenMargin)
                    .padding(.bottom, 90)
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { settings.isPrivate.toggle() } label: {
                        Image(systemName: settings.isPrivate ? "eye.slash" : "eye")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 15))
            TextField("Search transactions", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.accent)
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, 12)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.pill)
        .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(filters, id: \.self) { filter in
                    Button { selectedFilter = filter } label: {
                        CategoryChip(label: filter, isSelected: selectedFilter == filter)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if grouped.isEmpty {
                    VStack(spacing: AppSpacing.base) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(AppColors.textTertiary)
                        Text(searchText.isEmpty ? "No transactions yet" : "No results")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(grouped, id: \.0) { (dateLabel, txs) in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(dateLabel)
                                .labelCapsStyle()
                                .padding(.horizontal, AppSpacing.screenMargin)

                            NumeraCard(padding: 0) {
                                VStack(spacing: 0) {
                                    ForEach(Array(txs.enumerated()), id: \.element.id) { index, tx in
                                        TransactionRow(transaction: tx, isPrivate: settings.isPrivate)
                                        if index < txs.count - 1 {
                                            Divider()
                                                .background(AppColors.borderGlass)
                                                .padding(.horizontal, AppSpacing.base)
                                        }
                                    }
                                }
                                .padding(.vertical, AppSpacing.sm)
                            }
                            .padding(.horizontal, AppSpacing.screenMargin)
                        }
                    }
                }
                Spacer().frame(height: 120)
            }
            .padding(.top, AppSpacing.xl)
        }
    }
}

#Preview {
    ActivityView()
        .preferredColorScheme(.dark)
        .environment(TransactionStore())
        .environment(AppSettings())
}
