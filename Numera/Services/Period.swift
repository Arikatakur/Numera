import Foundation

/// A budgeting "month": starts on the user's month-start day, ends the day
/// before the next period starts. With the default start day of 1 this is a
/// plain calendar month.
struct Period: Equatable, Hashable {
    let start: Date  // inclusive, start of day
    let end: Date    // exclusive

    func contains(_ date: Date) -> Bool { date >= start && date < end }

    var dayCount: Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 30
    }
}

/// Aggregation window for Insights (Quanto's Weekly / Monthly / Quarterly /
/// Yearly tabs). `month` follows the user's month-start day; the others use
/// plain calendar boundaries.
enum PeriodUnit: String, CaseIterable, Identifiable {
    case week = "Weekly"
    case month = "Monthly"
    case quarter = "Quarterly"
    case year = "Yearly"

    var id: String { rawValue }
}

enum PeriodMath {
    /// Start-of-day on `startDay` of the given month, clamped to the month's length
    /// (start day 31 in February → Feb 28/29).
    private static func anchor(year: Int, month: Int, startDay: Int, calendar: Calendar) -> Date {
        var comps = DateComponents(year: year, month: month, day: 1)
        let firstOfMonth = calendar.date(from: comps) ?? .now
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 28
        comps.day = min(max(1, startDay), daysInMonth)
        return calendar.startOfDay(for: calendar.date(from: comps) ?? firstOfMonth)
    }

    /// The period anchored on `startDay` of `month`/`year`.
    static func period(year: Int, month: Int, startDay: Int, calendar: Calendar = .current) -> Period {
        let start = anchor(year: year, month: month, startDay: startDay, calendar: calendar)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let end = anchor(
            year: calendar.component(.year, from: nextMonth),
            month: calendar.component(.month, from: nextMonth),
            startDay: startDay,
            calendar: calendar
        )
        return Period(start: start, end: end)
    }

    /// The period containing `date`.
    static func period(containing date: Date, startDay: Int, calendar: Calendar = .current) -> Period {
        let candidate = period(
            year: calendar.component(.year, from: date),
            month: calendar.component(.month, from: date),
            startDay: startDay,
            calendar: calendar
        )
        guard date < candidate.start else { return candidate }
        let prev = calendar.date(byAdding: .month, value: -1, to: candidate.start) ?? date
        return period(
            year: calendar.component(.year, from: prev),
            month: calendar.component(.month, from: prev),
            startDay: startDay,
            calendar: calendar
        )
    }

    static func shift(_ p: Period, by months: Int, startDay: Int, calendar: Calendar = .current) -> Period {
        let moved = calendar.date(byAdding: .month, value: months, to: p.start) ?? p.start
        return period(
            year: calendar.component(.year, from: moved),
            month: calendar.component(.month, from: moved),
            startDay: startDay,
            calendar: calendar
        )
    }

    /// "July 2026" — labeled by the month the period starts in.
    static func label(_ p: Period) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: p.start)
    }

    /// "July"
    static func monthLabel(_ p: Period) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        return fmt.string(from: p.start)
    }

    /// "Jul"
    static func shortLabel(_ p: Period) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        return fmt.string(from: p.start)
    }

    /// Every day (start-of-day) in the period, in order. Capped defensively —
    /// high enough for yearly periods (366 days).
    static func days(in p: Period, calendar: Calendar = .current) -> [Date] {
        var days: [Date] = []
        var d = p.start
        while d < p.end && days.count < 400 {
            days.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? p.end
        }
        return days
    }

    // MARK: - Unit-aware periods (Insights Weekly/Monthly/Quarterly/Yearly)

    /// The week / month / quarter / year containing `date`. Months respect the
    /// user's `startDay`; weeks respect `firstWeekday` (1 = Sunday, 2 = Monday).
    static func period(
        of unit: PeriodUnit,
        containing date: Date,
        startDay: Int,
        firstWeekday: Int,
        calendar: Calendar = .current
    ) -> Period {
        switch unit {
        case .week:
            var cal = calendar
            cal.firstWeekday = firstWeekday
            let interval = cal.dateInterval(of: .weekOfYear, for: date)
                ?? DateInterval(start: cal.startOfDay(for: date), duration: 7 * 86_400)
            return Period(start: cal.startOfDay(for: interval.start), end: cal.startOfDay(for: interval.end))

        case .month:
            return period(containing: date, startDay: startDay, calendar: calendar)

        case .quarter:
            let comps = calendar.dateComponents([.year, .month], from: date)
            let month = comps.month ?? 1
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            let start = calendar.date(from: DateComponents(year: comps.year, month: quarterStartMonth, day: 1)) ?? date
            let end = calendar.date(byAdding: .month, value: 3, to: start) ?? date
            return Period(start: calendar.startOfDay(for: start), end: calendar.startOfDay(for: end))

        case .year:
            let year = calendar.component(.year, from: date)
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? date
            let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) ?? date
            return Period(start: calendar.startOfDay(for: start), end: calendar.startOfDay(for: end))
        }
    }

    /// Shifts `p` by whole units (e.g. -1 week, +2 quarters).
    static func shift(
        _ p: Period,
        by amount: Int,
        unit: PeriodUnit,
        startDay: Int,
        firstWeekday: Int,
        calendar: Calendar = .current
    ) -> Period {
        let component: Calendar.Component
        let value: Int
        switch unit {
        case .week:    component = .weekOfYear; value = amount
        case .month:   component = .month;      value = amount
        case .quarter: component = .month;      value = amount * 3
        case .year:    component = .year;       value = amount
        }
        let moved = calendar.date(byAdding: component, value: value, to: p.start) ?? p.start
        return period(of: unit, containing: moved, startDay: startDay, firstWeekday: firstWeekday, calendar: calendar)
    }

    /// Title for the period: "This week", "2–8 Jun", "July", "Q3 2026", "2026".
    static func title(_ p: Period, unit: PeriodUnit, relativeTo now: Date = .now) -> String {
        if p.contains(now) {
            switch unit {
            case .week:    return "This week"
            case .month:   return "This month"
            case .quarter: return "This quarter"
            case .year:    return "This year"
            }
        }
        switch unit {
        case .week:
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMM"
            let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: p.end) ?? p.end
            return "\(fmt.string(from: p.start)) – \(fmt.string(from: lastDay))"
        case .month:
            return monthLabel(p)
        case .quarter:
            return "Q\(quarterNumber(of: p)) \(Calendar.current.component(.year, from: p.start))"
        case .year:
            return String(Calendar.current.component(.year, from: p.start))
        }
    }

    /// Compact axis/tag label: "2 Jun", "Jul", "Q3 ’26", "2026".
    static func shortLabel(_ p: Period, unit: PeriodUnit) -> String {
        switch unit {
        case .week:
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMM"
            return fmt.string(from: p.start)
        case .month:
            return shortLabel(p)
        case .quarter:
            let year = Calendar.current.component(.year, from: p.start) % 100
            return "Q\(quarterNumber(of: p)) ’\(String(format: "%02d", year))"
        case .year:
            return String(Calendar.current.component(.year, from: p.start))
        }
    }

    private static func quarterNumber(of p: Period) -> Int {
        let month = Calendar.current.component(.month, from: p.start)
        return (month - 1) / 3 + 1
    }
}
