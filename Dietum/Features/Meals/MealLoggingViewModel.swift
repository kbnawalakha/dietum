import Foundation
import SwiftUI

@MainActor
final class MealLoggingViewModel: ObservableObject {
    enum AnalysisState: Equatable {
        case idle
        case analyzing
        case ready
        case saved
        case failed(String)
    }

    @Published var selectedMealType: MealType = .lunch
    @Published var notes: String = ""
    @Published var detectedFoods: [DetectedMealFood] = []
    @Published var analysisState: AnalysisState = .idle
    @Published var analysisNotes: String?

    private let detectionService: MealFoodDetectionService
    private let samplePhoto = PhotoMetadata(storageIdentifier: "meal-photo-mock")

    init(detectionService: MealFoodDetectionService = MockMealFoodDetectionService()) {
        self.detectionService = detectionService
    }

    func analyzeMockPhoto() async {
        guard analysisState != .analyzing else {
            return
        }

        analysisState = .analyzing
        analysisNotes = nil

        do {
            let result = try await detectionService.detectFoods(in: samplePhoto)
            detectedFoods = result.detectedFoods
            analysisNotes = result.notes
            analysisState = .ready
        } catch {
            analysisState = .failed("Mock analysis failed. Try again.")
            analysisNotes = nil
        }
    }

    func addFood() {
        detectedFoods.append(DetectedMealFood(name: "New food"))
        if case .idle = analysisState {
            analysisState = .ready
        }
    }

    func updateFood(id: DetectedMealFood.ID, name: String) {
        guard let index = detectedFoods.firstIndex(where: { $0.id == id }) else {
            return
        }

        detectedFoods[index].name = name
    }

    func removeFood(id: DetectedMealFood.ID) {
        detectedFoods.removeAll { $0.id == id }
        if detectedFoods.isEmpty, case .ready = analysisState {
            analysisState = .idle
        }
    }

    func saveDraft() {
        analysisState = .saved
    }

    var headline: String {
        switch analysisState {
        case .idle:
            return "Capture a meal photo, run mock analysis, then correct the detected foods."
        case .analyzing:
            return "Analyzing the sample meal locally."
        case .ready:
            return "Review the detected foods and make any corrections before saving."
        case .saved:
            return "Meal draft saved locally for now."
        case .failed(let message):
            return message
        }
    }

    var canSave: Bool {
        !detectedFoods.isEmpty && analysisState != .analyzing
    }
}
