import Foundation

enum CheckInField: String, CaseIterable, Hashable, Sendable {
    case weeklyWeight
    case energyNotes
    case hungerNotes
    case trainingNotes
}

struct CheckInDraft: Hashable, Sendable {
    var weeklyWeight: String = ""
    var energyNotes: String = ""
    var hungerNotes: String = ""
    var trainingNotes: String = ""

    var trimmedWeeklyWeight: String {
        weeklyWeight.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedEnergyNotes: String {
        energyNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedHungerNotes: String {
        hungerNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedTrainingNotes: String {
        trainingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var noteCount: Int {
        [trimmedEnergyNotes, trimmedHungerNotes, trimmedTrainingNotes]
            .filter { !$0.isEmpty }
            .count
    }
}

struct CheckInValidationIssue: Identifiable, Hashable, Sendable {
    var id = UUID()
    var field: CheckInField
    var message: String
}

struct CheckInValidationState: Hashable, Sendable {
    var issues: [CheckInValidationIssue] = []

    var isValid: Bool {
        issues.isEmpty
    }

    var primaryIssue: CheckInValidationIssue? {
        issues.first
    }

    var summaryText: String {
        switch issues.count {
        case 0:
            return "The check-in draft is ready to save."
        case 1:
            return issues[0].message
        default:
            return "\(issues.count) fields need attention before saving."
        }
    }
}

enum CheckInDraftValidator {
    static func validate(_ draft: CheckInDraft) -> CheckInValidationState {
        var issues: [CheckInValidationIssue] = []

        validateWeeklyWeight(draft, issues: &issues)

        return CheckInValidationState(issues: issues)
    }

    private static func validateWeeklyWeight(_ draft: CheckInDraft, issues: inout [CheckInValidationIssue]) {
        guard !draft.trimmedWeeklyWeight.isEmpty else {
            issues.append(CheckInValidationIssue(field: .weeklyWeight, message: "Enter your weekly weight."))
            return
        }

        guard let weight = Double(draft.trimmedWeeklyWeight.replacingOccurrences(of: ",", with: ".")) else {
            issues.append(CheckInValidationIssue(field: .weeklyWeight, message: "Enter the weight using numbers only."))
            return
        }

        guard (20...500).contains(weight) else {
            issues.append(CheckInValidationIssue(field: .weeklyWeight, message: "Weekly weight should be between 20 kg and 500 kg."))
            return
        }
    }
}
