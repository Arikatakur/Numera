import Foundation

/// Transient state for the first-run flow. Pure selections only — the actual
/// persistence (AppSettings, DataStore) lives in the step views where the
/// environment is available, so this stays a simple, previewable value holder.
@Observable
final class OnboardingModel {
    enum MonthStartMode: Hashable { case first, today, custom }
    enum ReminderChoice: Hashable { case morning, evening, notNow }

    // MARK: - Currency
    var currencyCode = "USD"

    // MARK: - Month start
    var monthStartMode: MonthStartMode = .first
    var customStartDay = 1

    /// The 1–31 day the chosen mode resolves to (clamped per month downstream).
    var resolvedMonthStartDay: Int {
        switch monthStartMode {
        case .first:  return 1
        case .today:  return Calendar.current.component(.day, from: .now)
        case .custom: return customStartDay
        }
    }

    // MARK: - Main account
    var accountName = "Main"
    var accountEmoji = "💳"
    /// Raw text; empty means "skip / no starting balance".
    var startingBalance = ""

    var startingBalanceDecimal: Decimal? {
        let trimmed = startingBalance.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX"))
    }

    // MARK: - First transaction
    var didLogFirstTransaction = false

    // MARK: - Reminder
    var reminderChoice: ReminderChoice?

    /// Hour of day for the chosen reminder slot (morning 9am / evening 9pm).
    var reminderHour: Int? {
        switch reminderChoice {
        case .morning: return 9
        case .evening: return 21
        case .notNow, .none: return nil
        }
    }
}
