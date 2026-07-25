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
}
