import Foundation
import SwiftUI

struct MealReminderSchedule: Hashable, Sendable {
    var mealType: MealType
    var time: DateComponents
    var isEnabled: Bool

    init(
        mealType: MealType,
        hour: Int,
        minute: Int = 0,
        isEnabled: Bool = true
    ) {
        self.mealType = mealType
        self.time = DateComponents(hour: hour, minute: minute)
        self.isEnabled = isEnabled
    }

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short

        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? .now
        return formatter.string(from: date)
    }
}

struct MealReminderStatus: Hashable, Sendable {
    var title: String
    var detail: String
    var symbolName: String
    var isPositive: Bool
}

@MainActor
final class MealReminderViewModel: ObservableObject {
    @Published var reminderSchedules: [MealReminderSchedule]
    @Published var reminderSummaryText: String
    @Published var reminderPermissionGranted: Bool

    init(
        reminderSchedules: [MealReminderSchedule] = [
            MealReminderSchedule(mealType: .breakfast, hour: 8),
            MealReminderSchedule(mealType: .lunch, hour: 13),
            MealReminderSchedule(mealType: .dinner, hour: 19),
            MealReminderSchedule(mealType: .snack, hour: 16)
        ],
        reminderPermissionGranted: Bool = true,
        reminderSummaryText: String = "Meal reminders are configured locally and ready to scan throughout the day."
    ) {
        self.reminderSchedules = reminderSchedules
        self.reminderPermissionGranted = reminderPermissionGranted
        self.reminderSummaryText = reminderSummaryText
    }

    var status: MealReminderStatus {
        if reminderPermissionGranted {
            return MealReminderStatus(
                title: "Reminders active",
                detail: "Local reminder scheduling is ready for the current meal plan.",
                symbolName: "bell.badge.fill",
                isPositive: true
            )
        } else {
            return MealReminderStatus(
                title: "Permission needed",
                detail: "Reminders are prepared, but notification access still needs to be enabled.",
                symbolName: "bell.slash.fill",
                isPositive: false
            )
        }
    }

    var enabledScheduleCount: Int {
        reminderSchedules.filter(\.isEnabled).count
    }

    var nextReminderText: String {
        guard let nextSchedule = reminderSchedules.first(where: { $0.isEnabled }) else {
            return "No reminders enabled yet."
        }

        return "Next reminder: \(nextSchedule.mealType.rawValue.capitalized) at \(nextSchedule.displayTime)"
    }

    var scheduleCountText: String {
        "\(enabledScheduleCount)/\(reminderSchedules.count) reminders enabled"
    }

    func toggleReminder(at index: Int) {
        guard reminderSchedules.indices.contains(index) else {
            return
        }

        reminderSchedules[index].isEnabled.toggle()
    }

    func updateSummary(_ text: String) {
        reminderSummaryText = text
    }
}
