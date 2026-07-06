import Foundation
import UserNotifications

/// Schedules the "log your expenses" local notification from the Reminder setting.
@MainActor
enum ReminderScheduler {
    static let requestId = "numera.reminder"

    /// Cancels and re-adds the repeating notification to match current settings.
    /// Returns false when the user has denied notification permission.
    @discardableResult
    static func reschedule(settings: AppSettings) async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        guard settings.reminderFrequency != .never else { return true }

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }

        var match = DateComponents()
        match.hour = settings.reminderHour
        match.minute = settings.reminderMinute
        switch settings.reminderFrequency {
        case .weekly:  match.weekday = settings.reminderWeekday
        case .monthly: match.day = settings.reminderDay
        case .daily, .never: break
        }

        let content = UNMutableNotificationContent()
        content.title = "Log your expenses"
        content.body = "Take 30 seconds to keep Numera up to date."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: match, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: requestId, content: content, trigger: trigger))
        return true
    }
}
