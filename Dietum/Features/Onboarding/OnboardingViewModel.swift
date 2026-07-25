import Foundation
import SwiftUI

struct OnboardingFieldGroup: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
    let fields: [String]
}

struct OnboardingImplementationPhase: Identifiable, Hashable, Sendable {
    let id = UUID()
    let title: String
    let detail: String
    let deliverable: String
    let checkpoints: [String]
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var draft: OnboardingDraft
    @Published private(set) var validationState: OnboardingValidationState

    let fieldGroups: [OnboardingFieldGroup] = [
        OnboardingFieldGroup(
            title: "Identity and body metrics",
            detail: "The first pass should capture the minimum profile shape needed for downstream nutrition and progress features.",
            fields: [
                "Name or nickname",
                "Height",
                "Current weight",
                "Goal weight",
                "Goal date"
            ]
        ),
        OnboardingFieldGroup(
            title: "Lifestyle context",
            detail: "These inputs help the app explain targets and future recommendations in a way that feels realistic.",
            fields: [
                "Workout days",
                "Workout intensity",
                "Sleep information"
            ]
        ),
        OnboardingFieldGroup(
            title: "Meal rhythm and preferences",
            detail: "Meal timing and preference inputs should shape the home screen and logging defaults later.",
            fields: [
                "Meal count",
                "Preferred meal times",
                "Heavy meal preference",
                "Light meal preference"
            ]
        ),
        OnboardingFieldGroup(
            title: "Nutrition targets",
            detail: "The profile flow should end with daily calorie and macro targets that can be edited later.",
            fields: [
                "Daily calorie target",
                "Protein target",
                "Carbohydrate target",
                "Fat target",
                "Fiber target"
            ]
        )
    ]

    let implementationPhases: [OnboardingImplementationPhase] = [
        OnboardingImplementationPhase(
            title: "1. Form scaffold",
            detail: "Build the screen structure, section order, and navigation shell before wiring storage.",
            deliverable: "A screen that walks through profile sections without committing data yet.",
            checkpoints: [
                "Display the profile sections in the product order",
                "Keep the layout quick to scan on iPhone",
                "Preserve the local-first visual language"
            ]
        ),
        OnboardingImplementationPhase(
            title: "2. Draft state",
            detail: "Introduce a view model that can hold the onboarding draft and validation state.",
            deliverable: "A typed draft that can later be shared with persistence and review logic.",
            checkpoints: [
                "Store field values in one place",
                "Prepare validation for required fields",
                "Expose form readiness to the view"
            ]
        ),
        OnboardingImplementationPhase(
            title: "3. Persistence bridge",
            detail: "Map the draft onto the SwiftData profile repository and keep the save path replaceable.",
            deliverable: "A save flow that writes the completed profile locally.",
            checkpoints: [
                "Reuse the existing local-only repository pattern",
                "Keep business rules out of the view",
                "Support editing the same profile later"
            ]
        ),
        OnboardingImplementationPhase(
            title: "4. Post-setup handoff",
            detail: "Finish the flow by returning the user to the dashboard with the profile in place.",
            deliverable: "A clear completion state and a path back to daily use.",
            checkpoints: [
                "Show a completion summary",
                "Keep the user in control of edits",
                "Leave room for later setup edits"
            ]
        )
    ]

    init(draft: OnboardingDraft = OnboardingDraft()) {
        self.draft = draft
        self.validationState = OnboardingDraftValidator.validate(draft)
    }

    var profileFieldCount: Int {
        fieldGroups.reduce(0) { $0 + $1.fields.count }
    }

    var phaseCountText: String {
        "\(implementationPhases.count) phases"
    }

    var fieldCountText: String {
        "\(profileFieldCount) profile fields"
    }

    var headline: String {
        "Plan the profile flow first so the real form, validation, and persistence can be built in order."
    }

    var summary: String {
        "This milestone keeps onboarding local-only, mirrors the app's design system, and defines the next implementation steps before the editable form arrives."
    }

    var completionMessage: String {
        "The current milestone ends at planning and scaffolding. The next milestone can replace the plan cards with a working profile form."
    }

    var isDraftValid: Bool {
        validationState.isValid
    }

    var draftReadinessText: String {
        validationState.summaryText
    }

    var primaryValidationIssue: OnboardingValidationIssue? {
        validationState.primaryIssue
    }

    func updateDraft(_ mutation: (inout OnboardingDraft) -> Void) {
        mutation(&draft)
        validationState = OnboardingDraftValidator.validate(draft)
    }

    func resetDraft() {
        updateDraft { draft in
            draft = OnboardingDraft()
        }
    }

    func validateDraft() -> OnboardingValidationState {
        validationState = OnboardingDraftValidator.validate(draft)
        return validationState
    }

    func binding<Value>(for keyPath: WritableKeyPath<OnboardingDraft, Value>) -> Binding<Value> {
        Binding(
            get: { self.draft[keyPath: keyPath] },
            set: { [weak self] newValue in
                self?.updateDraft { draft in
                    draft[keyPath: keyPath] = newValue
                }
            }
        )
    }
}

enum OnboardingField: String, CaseIterable, Hashable, Sendable {
    case displayName
    case heightCentimeters
    case currentWeightKilograms
    case goalWeightKilograms
    case goalDate
    case workoutDays
    case workoutIntensity
    case averageSleepHours
    case mealCount
    case preferredMealTimes
    case heavyMealSlot
    case lightMealSlot
    case dailyCalories
    case proteinGrams
    case carbohydrateGrams
    case fatGrams
    case fiberGrams

    var title: String {
        switch self {
        case .displayName:
            return "Name or nickname"
        case .heightCentimeters:
            return "Height"
        case .currentWeightKilograms:
            return "Current weight"
        case .goalWeightKilograms:
            return "Goal weight"
        case .goalDate:
            return "Goal date"
        case .workoutDays:
            return "Workout days"
        case .workoutIntensity:
            return "Workout intensity"
        case .averageSleepHours:
            return "Sleep information"
        case .mealCount:
            return "Meal count"
        case .preferredMealTimes:
            return "Preferred meal times"
        case .heavyMealSlot:
            return "Heavy meal preference"
        case .lightMealSlot:
            return "Light meal preference"
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

struct OnboardingDraft: Hashable, Sendable {
    var displayName: String = ""
    var heightCentimeters: String = ""
    var currentWeightKilograms: String = ""
    var goalWeightKilograms: String = ""
    var goalDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    var workoutDays: Set<Weekday> = []
    var workoutIntensity: WorkoutIntensity = .moderate
    var averageSleepHours: String = ""
    var mealCount: Int = 3
    var preferredMealTimes: String = ""
    var heavyMealPreference: String = ""
    var lightMealPreference: String = ""
    var dailyCalories: String = ""
    var proteinGrams: String = ""
    var carbohydrateGrams: String = ""
    var fatGrams: String = ""
    var fiberGrams: String = ""

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var requiredFieldCount: Int {
        16
    }

    var filledRequiredFieldCount: Int {
        [
            !trimmedDisplayName.isEmpty,
            !heightCentimeters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !currentWeightKilograms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !goalWeightKilograms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            true,
            !workoutDays.isEmpty,
            !averageSleepHours.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            mealCount > 0,
            !preferredMealTimes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !heavyMealPreference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !lightMealPreference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !dailyCalories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !proteinGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !carbohydrateGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !fatGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !fiberGrams.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ]
        .filter { $0 }
        .count
    }

    var progressText: String {
        "\(filledRequiredFieldCount)/\(requiredFieldCount)"
    }

    mutating func toggleWorkoutDay(_ day: Weekday) {
        if workoutDays.contains(day) {
            workoutDays.remove(day)
        } else {
            workoutDays.insert(day)
        }
    }
}

struct OnboardingValidationIssue: Identifiable, Hashable, Sendable {
    var id = UUID()
    var field: OnboardingField
    var message: String
}

struct OnboardingValidationState: Hashable, Sendable {
    var issues: [OnboardingValidationIssue] = []

    var isValid: Bool {
        issues.isEmpty
    }

    var primaryIssue: OnboardingValidationIssue? {
        issues.first
    }

    var summaryText: String {
        switch issues.count {
        case 0:
            return "The onboarding draft is ready to continue."
        case 1:
            return issues[0].message
        default:
            return "\(issues.count) fields need attention before continuing."
        }
    }
}

enum OnboardingDraftValidator {
    static func validate(_ draft: OnboardingDraft) -> OnboardingValidationState {
        var issues: [OnboardingValidationIssue] = []

        validateDisplayName(draft, issues: &issues)
        validateHeight(draft, issues: &issues)
        validateCurrentWeight(draft, issues: &issues)
        validateGoalWeight(draft, issues: &issues)
        validateGoalDate(draft, issues: &issues)
        validateWorkoutDays(draft, issues: &issues)
        validateSleep(draft, issues: &issues)
        validateMealCount(draft, issues: &issues)
        validateMealTimes(draft, issues: &issues)
        validateMealBalance(draft, issues: &issues)
        validateNutritionTargets(draft, issues: &issues)

        return OnboardingValidationState(issues: issues)
    }

    private static func validateDisplayName(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard !draft.trimmedDisplayName.isEmpty else {
            issues.append(OnboardingValidationIssue(field: .displayName, message: "Enter a name or nickname to personalize the setup."))
            return
        }

        guard draft.trimmedDisplayName.count <= 40 else {
            issues.append(OnboardingValidationIssue(field: .displayName, message: "Keep the name under 40 characters."))
            return
        }
    }

    private static func validateHeight(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard let height = parseDouble(draft.heightCentimeters) else {
            issues.append(OnboardingValidationIssue(field: .heightCentimeters, message: "Enter a height in centimeters."))
            return
        }

        guard (100...250).contains(height) else {
            issues.append(OnboardingValidationIssue(field: .heightCentimeters, message: "Height should be between 100 cm and 250 cm."))
            return
        }
    }

    private static func validateCurrentWeight(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard let currentWeight = parseDouble(draft.currentWeightKilograms) else {
            issues.append(OnboardingValidationIssue(field: .currentWeightKilograms, message: "Enter the current weight in kilograms."))
            return
        }

        guard (20...500).contains(currentWeight) else {
            issues.append(OnboardingValidationIssue(field: .currentWeightKilograms, message: "Current weight should be between 20 kg and 500 kg."))
            return
        }
    }

    private static func validateGoalWeight(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard let goalWeight = parseDouble(draft.goalWeightKilograms) else {
            issues.append(OnboardingValidationIssue(field: .goalWeightKilograms, message: "Enter the goal weight in kilograms."))
            return
        }

        guard (20...500).contains(goalWeight) else {
            issues.append(OnboardingValidationIssue(field: .goalWeightKilograms, message: "Goal weight should be between 20 kg and 500 kg."))
            return
        }
    }

    private static func validateGoalDate(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        if Calendar.current.compare(draft.goalDate, to: .now, toGranularity: .day) == .orderedAscending {
            issues.append(OnboardingValidationIssue(field: .goalDate, message: "Goal date should be today or later."))
        }
    }

    private static func validateWorkoutDays(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard Set(draft.workoutDays).count == draft.workoutDays.count else {
            issues.append(OnboardingValidationIssue(field: .workoutDays, message: "Workout days should not repeat the same day."))
            return
        }
    }

    private static func validateSleep(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard let sleepHours = parseDouble(draft.averageSleepHours) else {
            issues.append(OnboardingValidationIssue(field: .averageSleepHours, message: "Enter average sleep hours as a number."))
            return
        }

        guard (0...24).contains(sleepHours) else {
            issues.append(OnboardingValidationIssue(field: .averageSleepHours, message: "Sleep information should be between 0 and 24 hours."))
            return
        }
    }

    private static func validateMealCount(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard (1...8).contains(draft.mealCount) else {
            issues.append(OnboardingValidationIssue(field: .mealCount, message: "Meal count should be between 1 and 8."))
            return
        }
    }

    private static func validateMealTimes(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard !draft.preferredMealTimes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            issues.append(OnboardingValidationIssue(field: .preferredMealTimes, message: "Describe the preferred meal times."))
            return
        }

        guard !draft.heavyMealPreference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            issues.append(OnboardingValidationIssue(field: .heavyMealSlot, message: "Describe which meal should feel heavier."))
            return
        }

        guard !draft.lightMealPreference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            issues.append(OnboardingValidationIssue(field: .lightMealSlot, message: "Describe which meal should feel lighter."))
            return
        }
    }

    private static func validateMealBalance(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        let heavy = draft.heavyMealPreference.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let light = draft.lightMealPreference.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !heavy.isEmpty, heavy == light {
            issues.append(OnboardingValidationIssue(field: .heavyMealSlot, message: "Heavy and light meal preferences should describe different habits."))
        }
    }

    private static func validateNutritionTargets(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        validateCalories(draft, issues: &issues)
        validateMacroTarget(draft.proteinGrams, field: .proteinGrams, label: "Protein", issues: &issues)
        validateMacroTarget(draft.carbohydrateGrams, field: .carbohydrateGrams, label: "Carbohydrate", issues: &issues)
        validateMacroTarget(draft.fatGrams, field: .fatGrams, label: "Fat", issues: &issues)
        validateMacroTarget(draft.fiberGrams, field: .fiberGrams, label: "Fiber", issues: &issues)
    }

    private static func validateCalories(_ draft: OnboardingDraft, issues: inout [OnboardingValidationIssue]) {
        guard let calories = parseInt(draft.dailyCalories) else {
            issues.append(OnboardingValidationIssue(field: .dailyCalories, message: "Enter a daily calorie target."))
            return
        }

        guard (800...6_000).contains(calories) else {
            issues.append(OnboardingValidationIssue(field: .dailyCalories, message: "Daily calories should be between 800 and 6,000."))
            return
        }
    }

    private static func validateMacroTarget(
        _ value: String,
        field: OnboardingField,
        label: String,
        issues: inout [OnboardingValidationIssue]
    ) {
        guard let value = parseDouble(value) else {
            issues.append(OnboardingValidationIssue(field: field, message: "Enter a \(label.lowercased()) target."))
            return
        }

        guard value > 0 else {
            issues.append(OnboardingValidationIssue(field: field, message: "\(label) target should be greater than zero."))
            return
        }
    }

    private static func parseDouble(_ value: String) -> Double? {
        Double(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func parseInt(_ value: String) -> Int? {
        Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
