import SwiftUI

/// Transactions logged on a single day, opened by tapping a calendar cell.
/// Shows a per-day income/expense summary, the day's rows (tap to edit), or a
/// calm empty state when nothing was logged.
struct DayTransactionsSheet: View {
    let date: Date

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var editingTransaction: Transaction?

    private var dayTransactions: [Transaction] {
        store.transactions
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    private var expenseTotal: Decimal {
        dayTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var incomeTotal: Decimal {
        dayTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var title: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMM"
        return fmt.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                if dayTransactions.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppSpacing.lg) {
                            summaryCard
                            transactionsCard
                            Spacer().frame(height: AppSpacing.xl)
                        }
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.base)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(AppColors.accent)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(item: $editingTransaction) { tx in
            AddTransactionView(editing: tx)
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        NumeraCard {
            HStack(spacing: AppSpacing.xl) {
                summaryColumn(label: "Spent", amount: expenseTotal, color: AppColors.chartPurple)
                summaryColumn(label: "Income", amount: incomeTotal, color: AppColors.income)
                Spacer()
            }
        }
    }

    private func summaryColumn(label: String, amount: Decimal, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            MoneyText(amount: amount, size: 20)
        }
    }

    // MARK: - Rows

    private var transactionsCard: some View {
        SettingsCard {
            ForEach(Array(dayTransactions.enumerated()), id: \.element.id) { index, tx in
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
                if index < dayTransactions.count - 1 {
                    Divider()
                        .background(AppColors.borderSubtle)
                        .padding(.leading, 78)
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: AppSpacing.base) {
            Image(systemName: "tray")
                .font(.system(size: 40, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
            Text("No transactions")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Text("Nothing was logged on this day.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

#Preview {
    DayTransactionsSheet(date: .now)
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
}
