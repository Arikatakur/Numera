import SwiftUI

/// Premium "Recurring expenses" insight (Quanto Overview anatomy): the period's
/// recurring total, a chevron into the rule manager, and — for the monthly
/// range — a calendar marking the days a recurring expense lands on.
struct RecurringInsightsCard: View {
    let period: Period
    let unit: PeriodUnit

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    private var total: Decimal { store.recurringExpenseTotal(in: period) }
    private var rules: [RecurringRule] { store.activeRecurringExpenses }

    var body: some View {
        // Solid container: the calendar cells inside are Liquid Glass, and glass
        // must not stack on glass (same rule as the main calendar card).
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            NavigationLink {
                RecurringView()
                    .navigationTitle("Recurring")
                    .navigationBarTitleDisplayMode(.large)
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headerTitle)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        MoneyText(amount: total, size: 30)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.top, 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            recurringBody
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

    // The monthly range always shows the calendar (marks appear on recurring
    // days, empty otherwise, like the Quanto reference); other ranges list the
    // rules, or an empty state when there are none.
    @ViewBuilder
    private var recurringBody: some View {
        if unit == .month {
            RecurringMonthGrid(
                period: period,
                recurringDays: store.recurringExpenseDays(in: period),
                firstWeekday: settings.firstWeekday
            )
        } else if !rules.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(rules.enumerated()), id: \.element.id) { index, rule in
                    ruleRow(rule)
                    if index < rules.count - 1 {
                        Divider().background(AppColors.borderSubtle).padding(.leading, 52)
                    }
                }
            }
        } else {
            emptyState
        }
    }

    private func ruleRow(_ rule: RecurringRule) -> some View {
        HStack(spacing: AppSpacing.md) {
            EmojiIconTile(
                emoji: store.category(rule.categoryId)?.emoji ?? "🔁",
                colorHex: store.category(rule.categoryId)?.colorHex,
                size: 36
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text(rule.frequency.label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            MoneyText(amount: rule.amount, size: 15)
        }
        .padding(.vertical, AppSpacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 24, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
            Text("No recurring expenses yet")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Text("Add a repeating entry and it shows up here.")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.base)
    }

    private var headerTitle: String {
        let noun: String
        switch unit {
        case .week:    noun = "week"
        case .month:   noun = "month"
        case .quarter: noun = "quarter"
        case .year:    noun = "year"
        }
        return period.contains(.now)
            ? "Recurring expenses this \(noun)"
            : "Recurring expenses in \(PeriodMath.shortLabel(period, unit: unit))"
    }
}

/// Compact month grid that marks the days a recurring expense lands on. Shares
/// the weekday-aligned layout of `CalendarSpendGrid` but shows a marker dot
/// instead of a spend amount.
private struct RecurringMonthGrid: View {
    let period: Period
    let recurringDays: Set<Date>
    let firstWeekday: Int

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

    private var weeks: [[Date?]] {
        let cells: [Date?] = Array(repeating: nil, count: leadingBlanks) + days.map { Optional($0) }
        return stride(from: 0, to: cells.count, by: 7).map { start in
            var week = Array(cells[start..<min(start + 7, cells.count)])
            while week.count < 7 { week.append(nil) }
            return week
        }
    }

    var body: some View {
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
                                cell(day)
                            } else {
                                Color.clear.frame(maxWidth: .infinity).frame(height: 44)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(day)
        let isRecurring = recurringDays.contains(Calendar.current.startOfDay(for: day))
        let dayNumber = Calendar.current.component(.day, from: day)

        return VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isToday ? .black.opacity(0.8) : AppColors.textTertiary)
            Circle()
                .fill(isRecurring ? (isToday ? .black : AppColors.accent) : .clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .liquidGlassControl(
            RoundedRectangle(cornerRadius: 10, style: .continuous),
            tint: isToday ? AppColors.accent : nil,
            fallbackFill: isToday ? AppColors.accent : Color.white.opacity(0.05)
        )
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            RecurringInsightsCard(
                period: PeriodMath.period(of: .month, containing: .now, startDay: 1, firstWeekday: 1),
                unit: .month
            )
            .padding()
        }
        .background(AppColors.background)
    }
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
}
