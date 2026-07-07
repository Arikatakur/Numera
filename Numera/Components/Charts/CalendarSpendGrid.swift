import SwiftUI

/// Quanto Overview calendar: a weekday-aligned grid where every day shows its
/// spend amount. Day cells are Liquid Glass (blended in one container); today
/// is tinted with the accent. Cell size is fixed so amounts can never grow the
/// grid — long values scale down instead.
struct CalendarSpendGrid: View {
    let period: Period
    /// Totals keyed by start-of-day.
    let totals: [Date: Decimal]
    /// Calendar weekday unit: 1 = Sunday, 2 = Monday.
    let firstWeekday: Int
    /// Tapped day handler. When set, every cell becomes a button.
    var onSelectDay: ((Date) -> Void)? = nil

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

    /// Weekday-aligned rows of 7, padded to a full week. Building the rows
    /// explicitly (instead of a LazyVGrid) makes the grid measure its own
    /// height eagerly — a LazyVGrid inside the glass container under-reported
    /// its height, so the last week (26–31) spilled past the card.
    private var weeks: [[Date?]] {
        let cells: [Date?] = Array(repeating: nil, count: leadingBlanks) + days.map { Optional($0) }
        return stride(from: 0, to: cells.count, by: 7).map { start in
            var week = Array(cells[start..<min(start + 7, cells.count)])
            while week.count < 7 { week.append(nil) }
            return week
        }
    }

    var body: some View {
        // One glass container so the day cells' glass blends instead of stacking.
        LiquidGlassGroup(spacing: 5) {
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 18)
                    }
                }
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 5) {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(day)
                            } else {
                                Color.clear.frame(maxWidth: .infinity).frame(height: 46)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        if let onSelectDay {
            Button {
                Haptics.select()
                onSelectDay(day)
            } label: {
                cell(day)
            }
            .buttonStyle(.plain)
        } else {
            cell(day)
        }
    }

    private func cell(_ day: Date) -> some View {
        let total = totals[day] ?? 0
        let isToday = Calendar.current.isDateInToday(day)
        let dayNumber = Calendar.current.component(.day, from: day)

        return VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isToday ? .black.opacity(0.75) : AppColors.textTertiary)
            Text(amountLabel(total))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(
                    isToday ? .black : (total > 0 ? AppColors.textPrimary : AppColors.textTertiary.opacity(0.7))
                )
        }
        .padding(.horizontal, 3)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .liquidGlassControl(
            RoundedRectangle(cornerRadius: 10, style: .continuous),
            tint: isToday ? AppColors.accent : nil,
            fallbackFill: isToday ? AppColors.accent : Color.white.opacity(0.05)
        )
    }

    private func amountLabel(_ total: Decimal) -> String {
        if settings?.isPrivate == true { return "•" }
        return MoneyFormatter.compact((total as NSDecimalNumber).doubleValue)
    }
}
