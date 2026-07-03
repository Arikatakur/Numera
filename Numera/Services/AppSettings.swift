import Foundation

enum ReminderFrequency: String, CaseIterable, Identifiable {
    case never, daily, weekly, monthly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .never:   return "Never"
        case .daily:   return "Daily"
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

/// Device preferences, persisted in UserDefaults. Shared singleton so helpers
/// (Haptics, formatters) and views observe the same instance.
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private static let store = UserDefaults.standard

    // MARK: - Privacy
    var isPrivate: Bool { didSet { Self.store.set(isPrivate, forKey: "settings.isPrivate") } }

    // MARK: - Money display
    var currencyCode: String { didSet { Self.store.set(currencyCode, forKey: "settings.currencyCode") } }
    var displayCents: Bool { didSet { Self.store.set(displayCents, forKey: "settings.displayCents") } }

    // MARK: - Feel
    var hapticsEnabled: Bool { didSet { Self.store.set(hapticsEnabled, forKey: "settings.haptics") } }

    // MARK: - Period / calendar
    /// Day of month each budgeting period starts on (1–31, clamped per month).
    var monthStartDay: Int { didSet { Self.store.set(monthStartDay, forKey: "settings.monthStartDay") } }
    /// Calendar weekday unit: 1 = Sunday, 2 = Monday.
    var firstWeekday: Int { didSet { Self.store.set(firstWeekday, forKey: "settings.firstWeekday") } }

    // MARK: - Reminder
    var reminderFrequency: ReminderFrequency { didSet { Self.store.set(reminderFrequency.rawValue, forKey: "settings.reminderFrequency") } }
    var reminderHour: Int { didSet { Self.store.set(reminderHour, forKey: "settings.reminderHour") } }
    var reminderMinute: Int { didSet { Self.store.set(reminderMinute, forKey: "settings.reminderMinute") } }
    /// Weekday for weekly reminders (Calendar unit, 1 = Sunday).
    var reminderWeekday: Int { didSet { Self.store.set(reminderWeekday, forKey: "settings.reminderWeekday") } }
    /// Day of month for monthly reminders.
    var reminderDay: Int { didSet { Self.store.set(reminderDay, forKey: "settings.reminderDay") } }

    init() {
        let d = Self.store
        isPrivate         = d.bool(forKey: "settings.isPrivate")
        currencyCode      = d.string(forKey: "settings.currencyCode")
                            ?? Locale.current.currency?.identifier ?? "USD"
        displayCents      = d.object(forKey: "settings.displayCents") as? Bool ?? true
        hapticsEnabled    = d.object(forKey: "settings.haptics") as? Bool ?? true
        monthStartDay     = min(31, max(1, d.object(forKey: "settings.monthStartDay") as? Int ?? 1))
        firstWeekday      = d.object(forKey: "settings.firstWeekday") as? Int ?? 2
        reminderFrequency = ReminderFrequency(rawValue: d.string(forKey: "settings.reminderFrequency") ?? "") ?? .never
        reminderHour      = d.object(forKey: "settings.reminderHour") as? Int ?? 21
        reminderMinute    = d.object(forKey: "settings.reminderMinute") as? Int ?? 0
        reminderWeekday   = d.object(forKey: "settings.reminderWeekday") as? Int ?? 2
        reminderDay       = d.object(forKey: "settings.reminderDay") as? Int ?? 1
    }

    var currencySymbol: String { CurrencyInfo.symbol(for: currencyCode) }

    /// DatePicker-friendly view of the reminder time.
    var reminderTime: Date {
        get {
            Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
        }
        set {
            reminderHour = Calendar.current.component(.hour, from: newValue)
            reminderMinute = Calendar.current.component(.minute, from: newValue)
        }
    }
}
