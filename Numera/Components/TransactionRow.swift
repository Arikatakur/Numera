import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    var isPrivate: Bool = false

    private var amountColor: Color {
        transaction.type == .income ? AppColors.income : AppColors.textPrimary
    }

    private var amountPrefix: String {
        transaction.type == .income ? "+" : "-"
    }

    private var relativeDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(transaction.date)     { return "Today" }
        if cal.isDateInYesterday(transaction.date) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: transaction.date)
    }

    var body: some View {
        HStack(spacing: AppSpacing.base) {
            // Category icon
            ZStack {
                Circle()
                    .fill(AppColors.surfaceElevated)
                    .frame(width: 48, height: 48)
                Image(systemName: transaction.category.sfSymbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            // Title + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("\(transaction.category.rawValue) · \(relativeDate)")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Amount
            if isPrivate {
                Text("••••")
                    .moneyStyle(size: 16, color: amountColor)
            } else {
                Text("\(amountPrefix)$\(NSDecimalNumber(decimal: transaction.amount).doubleValue, specifier: "%.2f")")
                    .moneyStyle(size: 16, color: amountColor)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.md)
    }
}
