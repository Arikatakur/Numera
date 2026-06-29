import SwiftUI

struct ActivityView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var isPrivate = false
    @State private var showAddTransaction = false

    private let filters = ["All", "Expenses", "Income", "Recurring"]

    private var grouped: [(String, [Transaction])] {
        let filtered = MockData.transactions.filter { tx in
            let matchesFilter: Bool = {
                switch selectedFilter {
                case "Expenses":  return tx.type == .expense
                case "Income":    return tx.type == .income
                default:          return true
                }
            }()
            let matchesSearch = searchText.isEmpty || tx.title.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }

        let cal = Calendar.current
        let dict = Dictionary(grouping: filtered) { tx -> String in
            if cal.isDateInToday(tx.date)     { return "TODAY" }
            if cal.isDateInYesterday(tx.date) { return "YESTERDAY" }
            let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
            return fmt.string(from: tx.date).uppercased()
        }
        return dict.sorted { $0.key > $1.key }
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
                    Button { isPrivate.toggle() } label: {
                        Image(systemName: isPrivate ? "eye.slash" : "eye")
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
                ForEach(grouped, id: \.0) { (dateLabel, txs) in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(dateLabel)
                            .labelCapsStyle()
                            .padding(.horizontal, AppSpacing.screenMargin)

                        NumeraCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(Array(txs.enumerated()), id: \.element.id) { index, tx in
                                    TransactionRow(transaction: tx, isPrivate: isPrivate)
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
                Spacer().frame(height: 120)
            }
            .padding(.top, AppSpacing.xl)
        }
    }
}

#Preview {
    ActivityView()
        .preferredColorScheme(.dark)
}
