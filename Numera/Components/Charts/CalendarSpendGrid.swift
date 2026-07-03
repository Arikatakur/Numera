import SwiftUI

/// Quanto Overview calendar: a weekday-aligned grid where every day shows its
/// spend amount. Today is highlighted with the accent.
struct CalendarSpendGrid: View {
    let period: Period
    /// Totals keyed by start-of-day.
    let totals: [Date: Decimal]
    /// Calendar weekday unit: 1 = Sunday, 2 = Monday.
    let firstWeekday: Int

    @Environment(AppSettings.self) private var settings: AppSettings?

    private var days: [Date] { PeriodMath.days(in: period) }

    private var leadingBlanks: Int {
        guard let first = days.first else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: first)
        return (weekday - firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = Calendar.current.veryShortWeekdaySymbols  // Sunday-first
        let shift = max(0, min(6, firstWeekday - 1))
        return Array(symbols[shift...]) + Array(symbols[..<shift])
    }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
        LazyVGrid(columns: columns, spacing: 5) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(height: 18)
            }
            ForEach(0..<leadingBlanks, id: \.self) { _ in
                Color.clear.frame(height: 46)
            }
            ForEach(days, id: \.self) { day in
                cell(day)
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let total = totals[day] ?? 0
        let isToday = Calendar.current.isDateInToday(day)
        let dayNumber = Calendar.current.component(.day, from: day)

        return VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isToday ? .black.opacity(0.75) : AppColors.textTertiary)
            Text(amountLabel(total))
                .font(.system(size: 10, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(
                    isToday ? .black : (total > 0 ? AppColors.textPrimary : AppColors.textTertiary.opacity(0.7))
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isToday ? AppColors.accent : Color.white.opacity(0.04))
        )
    }

    private func amountLabel(_ total: Decimal) -> String {
        if settings?.isPrivate == true { return "•" }
        return MoneyFormatter.compact((total as NSDecimalNumber).doubleValue)
    }
}
