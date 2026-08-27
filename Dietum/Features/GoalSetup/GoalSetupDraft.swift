import Foundation

enum GoalSetupField: String, CaseIterable, Hashable, Sendable {
    case goalWeightKilograms
    case goalDate
    case dailyCalories
    case proteinGrams
    case carbohydrateGrams
    case fatGrams
    case fiberGrams

    var title: String {
        switch self {
        case .goalWeightKilograms:
            return "Goal weight"
        case .goalDate:
            return "Goal date"
        case .dailyCalories:
            return "Daily calorie target"
        case .proteinGrams:
            return "Protein target"
        case .carbohydrateGrams:
            return "Carbohydrate target"
        case .fatGrams:
            return "Fat target"
        case .fiberGrams:
            return "Fiber target"
        }
    }
}

struct GoalSetupDraft: Hashable, Sendable {
    var goalWeightKilograms: String = ""
    var goalDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    var dailyCalories: String = "2400"
    var proteinGrams: String = "180"
    var carbohydrateGrams: String = "240"
    var fatGrams: String = "80"
    var fiberGrams: String = "35"

    var filledFieldCount: Int {
        [
            !goalWeightKilograms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !dailyCalories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !proteinGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !carbohydrateGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !fatGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !fiberGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            goalDate.timeIntervalSince1970 > 0
        ]
        .filter { $0 }
        .count
    }

    var totalFieldCount: Int {
        7
    }

    var progressText: String {
        "\(filledFieldCount)/\(totalFieldCount)"
    }

    var readyToContinueText: String {
        "Finish the goal setup draft before continuing to the rest of the app."
    }
}

struct GoalSetupValidationIssue: Identifiable, Hashable, Sendable {
    var id = UUID()
    var field: GoalSetupField
    var message: String
}

struct GoalSetupValidationState: Hashable, Sendable {
    var issues: [GoalSetupValidationIssue] = []

    var isValid: Bool {
        issues.isEmpty
    }

    var primaryIssue: GoalSetupValidationIssue? {
        issues.first
    }

    var summaryText: String {
        switch issues.count {
        case 0:
            return "The goal setup draft is ready to continue."
        case 1:
            return issues[0].message
        default:
            return "\(issues.count) fields need attention before continuing."
        }
    }
}

enum GoalSetupDraftValidator {
    static func validate(_ draft: GoalSetupDraft) -> GoalSetupValidationState {
        var issues: [GoalSetupValidationIssue] = []

        validateGoalWeight(draft, issues: &issues)
        validateGoalDate(draft, issues: &issues)
        validateCalories(draft, issues: &issues)
        validateMacroTarget(draft.proteinGrams, field: .proteinGrams, label: "Protein", issues: &issues)
        validateMacroTarget(draft.carbohydrateGrams, field: .carbohydrateGrams, label: "Carbohydrate", issues: &issues)
        validateMacroTarget(draft.fatGrams, field: .fatGrams, label: "Fat", issues: &issues)
        validateMacroTarget(draft.fiberGrams, field: .fiberGrams, label: "Fiber", issues: &issues)

        return GoalSetupValidationState(issues: issues)
    }

    private static func validateGoalWeight(_ draft: GoalSetupDraft, issues: inout [GoalSetupValidationIssue]) {
        guard let goalWeight = parseDouble(draft.goalWeightKilograms) else {
            issues.append(GoalSetupValidationIssue(field: .goalWeightKilograms, message: "Enter a goal weight in kilograms."))
            return
        }

        guard (20...500).contains(goalWeight) else {
            issues.append(GoalSetupValidationIssue(field: .goalWeightKilograms, message: "Goal weight should be between 20 kg and 500 kg."))
            return
        }
    }

    private static func validateGoalDate(_ draft: GoalSetupDraft, issues: inout [GoalSetupValidationIssue]) {
        if Calendar.current.compare(draft.goalDate, to: .now, toGranularity: .day) == .orderedAscending {
            issues.append(GoalSetupValidationIssue(field: .goalDate, message: "Goal date should be today or later."))
        }
    }

    private static func validateCalories(_ draft: GoalSetupDraft, issues: inout [GoalSetupValidationIssue]) {
        guard let calories = parseInteger(draft.dailyCalories) else {
            issues.append(GoalSetupValidationIssue(field: .dailyCalories, message: "Enter a daily calorie target."))
            return
        }

        guard (800...6_000).contains(calories) else {
            issues.append(GoalSetupValidationIssue(field: .dailyCalories, message: "Daily calories should be between 800 and 6,000."))
            return
        }
    }

    private static func validateMacroTarget(
        _ rawValue: String,
        field: GoalSetupField,
        label: String,
        issues: inout [GoalSetupValidationIssue]
    ) {
        guard let value = parseDouble(rawValue) else {
            issues.append(GoalSetupValidationIssue(field: field, message: "Enter a \(label.lowercased()) target."))
            return
        }

        guard value > 0 else {
            issues.append(GoalSetupValidationIssue(field: field, message: "\(label) target should be greater than zero."))
            return
        }
    }

    private static func parseInteger(_ value: String) -> Int? {
        Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func parseDouble(_ value: String) -> Double? {
        Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
