import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    /// Show "Category · Date" under the title. Off in day-grouped lists.
    var showsDate: Bool = true

    @Environment(DataStore.self) private var store: DataStore?

    private var category: UserCategory? {
        guard transaction.type != .transfer else { return nil }
        return store?.displayCategory(for: transaction)
    }

    private var relativeDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(transaction.date) { return "Today" }
        if cal.isDateInYesterday(transaction.date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: transaction.date)
    }

    private var subtitle: String {
        let name = category?.name ?? "Transfer"
        return showsDate ? "\(name) · \(relativeDate)" : name
    }

    var body: some View {
        HStack(spacing: AppSpacing.base) {
            EmojiIconTile(
                emoji: category?.emoji ?? "🔁",
                colorHex: category?.colorHex
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            switch transaction.type {
            case .income:
                MoneyText(amount: transaction.amount, size: 16, color: AppColors.income, signed: true)
            case .expense:
                MoneyText(amount: -transaction.amount, size: 16)
            case .transfer:
                MoneyText(amount: transaction.amount, size: 16, color: AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.md)
        // The row is used as a plain-button label; without this only the icon
        // and text are tappable (the spacer gap in the middle isn't).
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 0) {
            TransactionRow(transaction: MockData.transactions[0])
            TransactionRow(transaction: MockData.transactions[2])
        }
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.card)
        .padding()
    }
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
}
