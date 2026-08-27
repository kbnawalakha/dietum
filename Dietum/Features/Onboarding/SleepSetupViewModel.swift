import Foundation
import SwiftUI

struct SleepSetupFieldGroup: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
    let fields: [String]
}

struct SleepSetupValidationIssue: Identifiable, Hashable, Sendable {
    var id = UUID()
    var message: String
}

struct SleepSetupValidationState: Hashable, Sendable {
    var issues: [SleepSetupValidationIssue] = []

    var isValid: Bool {
        issues.isEmpty
    }

    var summaryText: String {
        switch issues.count {
        case 0:
            return "Sleep setup is ready to continue."
        case 1:
            return issues[0].message
        default:
            return "\(issues.count) sleep fields need attention."
        }
    }
}

@MainActor
final class SleepSetupViewModel: ObservableObject {
    @Published var averageSleepHours: String
    @Published var sleepSchedule: String
    @Published var sleepNotes: String
    @Published private(set) var validationState: SleepSetupValidationState

    let fieldGroups: [SleepSetupFieldGroup] = [
        SleepSetupFieldGroup(
            title: "Sleep baseline",
            detail: "Capture the average amount of sleep first so the rest of the app can explain recovery context later.",
            fields: [
                "Average sleep hours",
                "Sleep schedule"
            ]
        ),
        SleepSetupFieldGroup(
            title: "Sleep context",
            detail: "A short note can capture whether the current routine feels stable, interrupted, or inconsistent.",
            fields: [
                "Sleep notes"
            ]
        )
    ]

    init(
        averageSleepHours: String = "",
        sleepSchedule: String = "",
        sleepNotes: String = ""
    ) {
        self.averageSleepHours = averageSleepHours
        self.sleepSchedule = sleepSchedule
        self.sleepNotes = sleepNotes
        self.validationState = Self.validate(
            averageSleepHours: averageSleepHours,
            sleepSchedule: sleepSchedule,
            sleepNotes: sleepNotes
        )
    }

    var isReady: Bool {
        validationState.isValid
    }

    var readinessText: String {
        validationState.summaryText
    }

    var profileFieldCount: Int {
        fieldGroups.reduce(0) { $0 + $1.fields.count }
    }

    func updateAverageSleepHours(_ value: String) {
        averageSleepHours = value
        validate()
    }

    func updateSleepSchedule(_ value: String) {
        sleepSchedule = value
        validate()
    }

    func updateSleepNotes(_ value: String) {
        sleepNotes = value
        validate()
    }

    func validate() -> SleepSetupValidationState {
        validationState = Self.validate(
            averageSleepHours: averageSleepHours,
            sleepSchedule: sleepSchedule,
            sleepNotes: sleepNotes
        )
        return validationState
    }

    private static func validate(
        averageSleepHours: String,
        sleepSchedule: String,
        sleepNotes: String
    ) -> SleepSetupValidationState {
        var issues: [SleepSetupValidationIssue] = []

        if !averageSleepHours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let sleepHours = Double(averageSleepHours.trimmingCharacters(in: .whitespacesAndNewlines)) {
                if !(0...24).contains(sleepHours) {
                    issues.append(SleepSetupValidationIssue(message: "Average sleep hours should be between 0 and 24."))
                }
            } else {
                issues.append(SleepSetupValidationIssue(message: "Enter average sleep hours as a number."))
            }
        } else {
            issues.append(SleepSetupValidationIssue(message: "Enter average sleep hours to finish sleep setup."))
        }

        if sleepSchedule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(SleepSetupValidationIssue(message: "Describe the current sleep schedule."))
        }

        if sleepNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(SleepSetupValidationIssue(message: "Add a short note about sleep consistency or recovery."))
        }

        return SleepSetupValidationState(issues: issues)
    }
}
