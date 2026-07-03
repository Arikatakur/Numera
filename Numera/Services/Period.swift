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

    /// Every day (start-of-day) in the period, in order.
    static func days(in p: Period, calendar: Calendar = .current) -> [Date] {
        var days: [Date] = []
        var d = p.start
        while d < p.end && days.count < 62 {
            days.append(d)
            d = calendar.date(byAdding: .day, value: 1, to: d) ?? p.end
        }
        return days
    }
}
