import Foundation
import SwiftUI

@MainActor
final class GoalSetupViewModel: ObservableObject {
    @Published var draft: GoalSetupDraft
    @Published private(set) var validationState: GoalSetupValidationState

    init(draft: GoalSetupDraft = GoalSetupDraft()) {
        self.draft = draft
        self.validationState = GoalSetupDraftValidator.validate(draft)
    }

    var headline: String {
        "Shape the goal setup first so the target weight, date, and nutrition targets stay editable."
    }

    var summary: String {
        "Goal setup stays local and intentionally lightweight until the saved profile and persistence bridge arrive."
    }

    var completionMessage: String {
        "The draft is ready to hand off once the goal values are complete and valid."
    }

    var isDraftValid: Bool {
        validationState.isValid
    }

    var draftReadinessText: String {
        validationState.summaryText
    }

    var primaryValidationIssue: GoalSetupValidationIssue? {
        validationState.primaryIssue
    }

    func updateDraft(_ mutation: (inout GoalSetupDraft) -> Void) {
        mutation(&draft)
        validationState = GoalSetupDraftValidator.validate(draft)
    }

    func resetDraft() {
        updateDraft { draft in
            draft = GoalSetupDraft()
        }
    }

    func validateDraft() -> GoalSetupValidationState {
        validationState = GoalSetupDraftValidator.validate(draft)
        return validationState
    }

    func binding<Value>(for keyPath: WritableKeyPath<GoalSetupDraft, Value>) -> Binding<Value> {
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
