import SwiftUI

/// "Set yourself a reminder to add your expenses." — frequency options with a
/// native time wheel (Quanto Reminder screen). Schedules local notifications.
struct ReminderView: View {
    @Environment(AppSettings.self) private var settings

    @State private var permissionDenied = false

    private let weekdays: [(unit: Int, name: String)] = [
        (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"), (5, "Thursday"),
        (6, "Friday"), (7, "Saturday"), (1, "Sunday"),
    ]

    var body: some View {
        @Bindable var settings = settings

        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Set yourself a reminder to add your expenses.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)

                    VStack(spacing: AppSpacing.md) {
                        ForEach(ReminderFrequency.allCases) { frequency in
                            optionRow(frequency)
                        }
                    }

                    if permissionDenied {
                        Text("Notifications are turned off for Numera. Enable them in iOS Settings → Notifications.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.warning)
                    }

                    if settings.reminderFrequency == .weekly {
                        weekdayPicker
                    }

                    if settings.reminderFrequency == .monthly {
                        dayOfMonthPicker
                    }

                    if settings.reminderFrequency != .never {
                        Text(scheduleSummary)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, AppSpacing.sm)

                        DatePicker(
                            "",
                            selection: $settings.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, AppSpacing.sm)
            }
        }
        .navigationTitle("Reminder")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onChange(of: settings.reminderFrequency) { reschedule() }
        .onChange(of: settings.reminderHour) { reschedule() }
        .onChange(of: settings.reminderMinute) { reschedule() }
        .onChange(of: settings.reminderWeekday) { reschedule() }
        .onChange(of: settings.reminderDay) { reschedule() }
    }

    private func reschedule() {
        Task {
            let granted = await ReminderScheduler.reschedule(settings: settings)
            permissionDenied = !granted && settings.reminderFrequency != .never
        }
    }

    private func optionRow(_ frequency: ReminderFrequency) -> some View {
        let isSelected = settings.reminderFrequency == frequency
        return Button {
            Haptics.select()
            settings.reminderFrequency = frequency
        } label: {
            HStack {
                Text(frequency.label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 16)
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(isSelected ? AppColors.accent : AppColors.borderGlass, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var weekdayPicker: some View {
        SettingsCard {
            SettingsRow(icon: "calendar", title: "Day of week") {
                Menu {
                    ForEach(weekdays, id: \.unit) { weekday in
                        Button(weekday.name) { settings.reminderWeekday = weekday.unit }
                    }
                } label: {
                    SettingsValueChevron(value: weekdayName(settings.reminderWeekday))
                }
            }
        }
    }

    private var dayOfMonthPicker: some View {
        SettingsCard {
            SettingsRow(icon: "calendar", title: "Day of month") {
                Menu {
                    ForEach(1...28, id: \.self) { day in
                        Button("\(day)") { settings.reminderDay = day }
                    }
                } label: {
                    SettingsValueChevron(value: "\(settings.reminderDay)")
                }
            }
        }
    }

    private func weekdayName(_ unit: Int) -> String {
        weekdays.first { $0.unit == unit }?.name ?? "Monday"
    }

    private var scheduleSummary: String {
        let time = settings.reminderTime.formatted(date: .omitted, time: .shortened)
        switch settings.reminderFrequency {
        case .daily:   return "Every day at \(time)"
        case .weekly:  return "Every \(weekdayName(settings.reminderWeekday)) at \(time)"
        case .monthly: return "Every month on day \(settings.reminderDay) at \(time)"
        case .never:   return ""
        }
    }
}

#Preview {
    NavigationStack {
        ReminderView()
    }
    .preferredColorScheme(.dark)
    .environment(AppSettings.shared)
}
