import Foundation
import SwiftUI

struct MealLoggingDraft: Hashable, Sendable {
    var mealType: MealType = .lunch
    var notes: String = ""
    var photoDescription: String = "Mock meal photo"
    var detectedFoods: [DetectedMealFood] = []

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        detectedFoods.isEmpty && trimmedNotes.isEmpty
    }
}

struct MealLoggingSummary: Hashable, Sendable {
    var mealType: MealType
    var itemCount: Int
    var confidenceText: String
    var notes: String

    static let empty = MealLoggingSummary(
        mealType: .custom,
        itemCount: 0,
        confidenceText: "No analysis yet",
        notes: "Run the mock detector to populate a meal draft."
    )
}

@MainActor
final class MealLoggingViewModel: ObservableObject {
    enum AnalysisState: Equatable {
        case idle
        case analyzing
        case ready
        case needsReview
        case saved
        case failed(String)
    }

    @Published var draft: MealLoggingDraft
    @Published var analysisState: AnalysisState = .idle
    @Published var analysisNotes: String?
    @Published var selectedItemID: DetectedMealFood.ID?
    @Published private(set) var reviewedItemIDs: Set<DetectedMealFood.ID> = []

    private let detectionService: MealFoodDetectionService
    private let samplePhoto = PhotoMetadata(storageIdentifier: "meal-photo-mock")

    init(
        draft: MealLoggingDraft = MealLoggingDraft(),
        detectionService: MealFoodDetectionService = MockMealFoodDetectionService()
    ) {
        self.draft = draft
        self.detectionService = detectionService
    }

    var detectedFoods: [DetectedMealFood] {
        draft.detectedFoods
    }

    var headline: String {
        switch analysisState {
        case .idle:
            return "Capture a meal photo, run mock analysis, then correct the detected foods."
        case .analyzing:
            return "Analyzing the sample meal locally."
        case .ready:
            return "Review the detected foods and make any corrections before saving."
        case .needsReview:
            return "Some foods still need attention before the meal can be saved."
        case .saved:
            return "Meal draft saved locally for now."
        case .failed(let message):
            return message
        }
    }

    var canSave: Bool {
        !draft.detectedFoods.isEmpty
            && analysisState != .analyzing
            && draft.detectedFoods.allSatisfy { food in
                !food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && reviewedItemIDs.contains(food.id)
            }
    }

    var reviewStatusText: String {
        guard !draft.detectedFoods.isEmpty else {
            return "Run the mock detector before reviewing foods."
        }

        let remaining = draft.detectedFoods.count - draft.detectedFoods.filter { reviewedItemIDs.contains($0.id) }.count
        if remaining == 0 {
            return "Every detected food has been confirmed."
        }

        return "\(remaining) food\(remaining == 1 ? "" : "s") still need confirmation before saving."
    }

    func isFoodReviewed(_ id: DetectedMealFood.ID) -> Bool {
        reviewedItemIDs.contains(id)
    }

    func foodNeedsAttention(_ food: DetectedMealFood) -> Bool {
        food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (food.confidence ?? 0) < 0.8
    }

    var summary: MealLoggingSummary {
        guard !draft.detectedFoods.isEmpty else {
            return .empty
        }

        let confidenceValues = draft.detectedFoods.compactMap(\.confidence)
        let averageConfidence = confidenceValues.isEmpty ? nil : confidenceValues.reduce(0, +) / Double(confidenceValues.count)
        let confidenceText = averageConfidence.map { "\(Int($0 * 100))% average confidence" } ?? "Confidence not available"

        return MealLoggingSummary(
            mealType: draft.mealType,
            itemCount: draft.detectedFoods.count,
            confidenceText: confidenceText,
            notes: draft.trimmedNotes.isEmpty ? "Add notes after the mock analysis if needed." : draft.trimmedNotes
        )
    }

    var reviewPillText: String {
        switch analysisState {
        case .idle:
            return "Awaiting analysis"
        case .analyzing:
            return "Analyzing"
        case .ready:
            return "Ready to review"
        case .needsReview:
            return "Needs review"
        case .saved:
            return "Saved"
        case .failed:
            return "Error"
        }
    }

    func analyzeMockPhoto() async {
        guard analysisState != .analyzing else {
            return
        }

        analysisState = .analyzing
        analysisNotes = nil
        selectedItemID = nil

        do {
            let result = try await detectionService.detectFoods(in: samplePhoto)
            updateDraft { draft in
                draft.detectedFoods = result.detectedFoods
            }
            reviewedItemIDs = []
            analysisNotes = result.notes
            analysisState = result.detectedFoods.isEmpty ? .needsReview : .ready
        } catch {
            analysisState = .failed("Mock analysis failed. Try again.")
            analysisNotes = nil
        }
    }

    func addFood() {
        updateDraft { draft in
            draft.detectedFoods.append(DetectedMealFood(name: "New food"))
        }
        if case .idle = analysisState {
            analysisState = .needsReview
        }
    }

    func toggleFoodReviewed(_ id: DetectedMealFood.ID) {
        guard let food = draft.detectedFoods.first(where: { $0.id == id }),
              !food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            selectedItemID = id
            analysisState = .needsReview
            return
        }

        if reviewedItemIDs.contains(id) {
            reviewedItemIDs.remove(id)
        } else {
            reviewedItemIDs.insert(id)
        }
    }

    func updateMealType(_ mealType: MealType) {
        updateDraft { draft in
            draft.mealType = mealType
        }
    }

    func updateNotes(_ notes: String) {
        updateDraft { draft in
            draft.notes = notes
        }
    }

    func updateFood(id: DetectedMealFood.ID, name: String) {
        updateDraft { draft in
            guard let index = draft.detectedFoods.firstIndex(where: { $0.id == id }) else {
                return
            }

            draft.detectedFoods[index].name = name
        }
        reviewedItemIDs.remove(id)
        analysisState = .needsReview
        selectedItemID = id
    }

    func updateFoodConfidence(id: DetectedMealFood.ID, confidence: Double?) {
        updateDraft { draft in
            guard let index = draft.detectedFoods.firstIndex(where: { $0.id == id }) else {
                return
            }

            draft.detectedFoods[index].confidence = confidence
        }
        reviewedItemIDs.remove(id)
        analysisState = .needsReview
    }

    func removeFood(id: DetectedMealFood.ID) {
        updateDraft { draft in
            draft.detectedFoods.removeAll { $0.id == id }
        }
        reviewedItemIDs.remove(id)
        if draft.detectedFoods.isEmpty, case .ready = analysisState {
            analysisState = .needsReview
        }
    }

    func toggleItemReview(_ id: DetectedMealFood.ID) {
        selectedItemID = selectedItemID == id ? nil : id
    }

    func saveDraft() {
        guard canSave else {
            return
        }

        analysisState = .saved
    }

    private func updateDraft(_ mutation: (inout MealLoggingDraft) -> Void) {
        mutation(&draft)
    }
}
