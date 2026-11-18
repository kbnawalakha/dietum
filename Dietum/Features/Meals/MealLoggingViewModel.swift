import Foundation
import SwiftUI
import UIKit

struct MealLoggingDraft: Hashable, Sendable {
    var mealType: MealType = .lunch
    var notes: String = ""
    var photoDescription: String = ""
    var foodDescription: String = ""
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
    var nutrition: NutritionAmounts

    static let empty = MealLoggingSummary(
        mealType: .custom,
        itemCount: 0,
        confidenceText: "No analysis yet",
        notes: "Describe the meal to calculate an estimate.",
        nutrition: NutritionAmounts()
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
    @Published var photoSelectionError: String?
    @Published private(set) var reviewedItemIDs: Set<DetectedMealFood.ID> = []
    @Published private(set) var selectedPhoto: UIImage?
    @Published private(set) var todaySavedMeals: [MealEntry] = []

    private let detectionService: MealFoodDetectionService
    private let mealEntryRepository: (any MealEntryRepository)?

    init(
        draft: MealLoggingDraft = MealLoggingDraft(),
        detectionService: MealFoodDetectionService = FoodDataCentralMealAnalysisService(),
        mealEntryRepository: (any MealEntryRepository)? = nil
    ) {
        self.draft = draft
        self.detectionService = detectionService
        self.mealEntryRepository = mealEntryRepository
        self.photoSelectionError = nil
    }

    var detectedFoods: [DetectedMealFood] {
        draft.detectedFoods
    }

    var hasSelectedPhoto: Bool {
        selectedPhoto != nil
    }

    var canAnalyze: Bool {
        !draft.foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasSelectedPhoto
    }

    func setSelectedPhoto(_ image: UIImage) {
        selectedPhoto = image
        photoSelectionError = nil
        updateDraft { draft in
            draft.photoDescription = "Selected local meal photo"
        }
        analysisState = .idle
        analysisNotes = nil
        selectedItemID = nil
        reviewedItemIDs = []
    }

    func photoSelectionFailed() {
        photoSelectionError = "The meal photo could not be loaded. Try choosing another photo or add a description instead."
    }

    var headline: String {
        switch analysisState {
        case .idle:
            return "Describe the meal, then review the Vision and USDA nutrition estimate."
        case .analyzing:
            return "Identifying foods and looking up nutrition data."
        case .ready:
            return "Review the detected foods and make any corrections before saving."
        case .needsReview:
            return "Some foods may need attention. You can review them before saving."
        case .saved:
            return "Meal draft saved locally for now."
        case .failed(let message):
            return message
        }
    }

    var canSave: Bool {
        !draft.detectedFoods.isEmpty
            && (analysisState == .ready || analysisState == .needsReview)
            && draft.detectedFoods.allSatisfy { food in
                !food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    var reviewStatusText: String {
        guard !draft.detectedFoods.isEmpty else {
            return "Describe the meal and run analysis before reviewing foods."
        }

        let remaining = draft.detectedFoods.count - draft.detectedFoods.filter { reviewedItemIDs.contains($0.id) }.count
        if remaining == 0 {
            return "Every detected food has been confirmed."
        }

        return "\(remaining) food\(remaining == 1 ? "" : "s") have not been manually confirmed. Saving remains available."
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
            notes: draft.trimmedNotes.isEmpty ? "Review the estimate before saving." : draft.trimmedNotes,
            nutrition: nutritionTotals
        )
    }

    var nutritionTotals: NutritionAmounts {
        draft.detectedFoods.reduce(into: NutritionAmounts()) { totals, food in
            totals.calories += food.nutrition.calories
            totals.proteinGrams += food.nutrition.proteinGrams
            totals.carbohydrateGrams += food.nutrition.carbohydrateGrams
            totals.fatGrams += food.nutrition.fatGrams
            totals.fiberGrams += food.nutrition.fiberGrams
            totals.micronutrients.sugarGrams += food.nutrition.micronutrients.sugarGrams
            totals.micronutrients.saturatedFatGrams += food.nutrition.micronutrients.saturatedFatGrams
            totals.micronutrients.cholesterolMilligrams += food.nutrition.micronutrients.cholesterolMilligrams
            totals.micronutrients.sodiumMilligrams += food.nutrition.micronutrients.sodiumMilligrams
            totals.micronutrients.potassiumMilligrams += food.nutrition.micronutrients.potassiumMilligrams
            totals.micronutrients.calciumMilligrams += food.nutrition.micronutrients.calciumMilligrams
            totals.micronutrients.ironMilligrams += food.nutrition.micronutrients.ironMilligrams
            totals.micronutrients.magnesiumMilligrams += food.nutrition.micronutrients.magnesiumMilligrams
            totals.micronutrients.phosphorusMilligrams += food.nutrition.micronutrients.phosphorusMilligrams
            totals.micronutrients.zincMilligrams += food.nutrition.micronutrients.zincMilligrams
            totals.micronutrients.vitaminAMicrograms += food.nutrition.micronutrients.vitaminAMicrograms
            totals.micronutrients.vitaminCMilligrams += food.nutrition.micronutrients.vitaminCMilligrams
            totals.micronutrients.vitaminDMicrograms += food.nutrition.micronutrients.vitaminDMicrograms
            totals.micronutrients.vitaminEMilligrams += food.nutrition.micronutrients.vitaminEMilligrams
            totals.micronutrients.vitaminKMicrograms += food.nutrition.micronutrients.vitaminKMicrograms
            totals.micronutrients.thiaminMilligrams += food.nutrition.micronutrients.thiaminMilligrams
            totals.micronutrients.riboflavinMilligrams += food.nutrition.micronutrients.riboflavinMilligrams
            totals.micronutrients.niacinMilligrams += food.nutrition.micronutrients.niacinMilligrams
            totals.micronutrients.vitaminB6Milligrams += food.nutrition.micronutrients.vitaminB6Milligrams
            totals.micronutrients.folateMicrograms += food.nutrition.micronutrients.folateMicrograms
            totals.micronutrients.vitaminB12Micrograms += food.nutrition.micronutrients.vitaminB12Micrograms
            totals.micronutrients.cholineMilligrams += food.nutrition.micronutrients.cholineMilligrams
        }
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

    func analyzeMeal() async {
        guard analysisState != .analyzing else {
            return
        }

        guard canAnalyze else {
            analysisState = .failed("Describe the food or choose a photo before analyzing.")
            analysisNotes = "Add a general description such as chicken, rice, and vegetables."
            return
        }

        analysisState = .analyzing
        analysisNotes = nil
        selectedItemID = nil

        do {
            let result = try await detectionService.analyzeMeal(
                description: draft.foodDescription,
                photo: selectedPhoto.map {
                    PhotoMetadata(
                        storageIdentifier: "meal-photo-selected",
                        imageData: $0.jpegData(compressionQuality: 0.85)
                    )
                }
            )
            updateDraft { draft in
                draft.detectedFoods = result.detectedFoods
            }
            reviewedItemIDs = []
            analysisNotes = result.notes
            analysisState = result.detectedFoods.isEmpty ? .needsReview : .ready
        } catch is CancellationError {
            analysisState = .idle
            analysisNotes = "Analysis was canceled. Add a description or photo and try again."
        } catch let error as FoodDataCentralMealAnalysisError {
            analysisState = .failed(error.localizedDescription)
            analysisNotes = "No estimate was invented. Add a clearer description, configure USDA FoodData Central, or try another photo."
        } catch {
            analysisState = .failed("Meal analysis could not be completed.")
            analysisNotes = "Check the meal description or photo, then try again."
        }
    }

    func updateFoodDescription(_ description: String) {
        updateDraft { draft in
            draft.foodDescription = description
            draft.detectedFoods = []
        }
        reviewedItemIDs = []
        selectedItemID = nil
        analysisState = .idle
        analysisNotes = nil
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

    func updateFoodMacros(id: DetectedMealFood.ID, protein: Double, carbohydrates: Double, fat: Double) {
        updateDraft { draft in
            guard let index = draft.detectedFoods.firstIndex(where: { $0.id == id }) else {
                return
            }

            let fiber = draft.detectedFoods[index].nutrition.fiberGrams
            let updatedNutrition = NutritionAmounts(
                calories: Int((protein * 4 + carbohydrates * 4 + fat * 9).rounded()),
                proteinGrams: max(0, protein),
                carbohydrateGrams: max(0, carbohydrates),
                fatGrams: max(0, fat),
                fiberGrams: fiber,
                micronutrients: draft.detectedFoods[index].nutrition.micronutrients
            )
            draft.detectedFoods[index].nutrition = updatedNutrition
            draft.detectedFoods[index].nutritionPer100Grams = updatedNutrition.scaled(
                toGrams: 10_000 / max(draft.detectedFoods[index].estimatedWeightGrams, 1)
            )
        }
        reviewedItemIDs.remove(id)
        analysisState = .needsReview
    }

    func updateFoodWeight(id: DetectedMealFood.ID, grams: Double) {
        updateDraft { draft in
            guard let index = draft.detectedFoods.firstIndex(where: { $0.id == id }) else {
                return
            }

            let clampedGrams = min(max(grams, 1), 2_000)
            draft.detectedFoods[index].estimatedWeightGrams = clampedGrams
            draft.detectedFoods[index].nutrition = draft.detectedFoods[index].nutritionPer100Grams.scaled(toGrams: clampedGrams)
        }
        reviewedItemIDs.remove(id)
        analysisState = .needsReview
    }

    func updateFoodServings(id: DetectedMealFood.ID, servings: Double) {
        updateDraft { draft in
            guard let index = draft.detectedFoods.firstIndex(where: { $0.id == id }),
                  let servingSizeGrams = draft.detectedFoods[index].servingSizeGrams else {
                return
            }

            let clampedServings = min(max(servings, 0.25), 50)
            draft.detectedFoods[index].servings = clampedServings
            draft.detectedFoods[index].estimatedWeightGrams = servingSizeGrams * clampedServings
            draft.detectedFoods[index].nutrition = draft.detectedFoods[index].nutritionPer100Grams.scaled(
                toGrams: draft.detectedFoods[index].estimatedWeightGrams
            )
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

    func saveDraft() async {
        guard canSave else {
            if draft.detectedFoods.isEmpty {
                analysisState = .failed("Analyze the meal before saving it.")
                analysisNotes = "Choose a photo or describe the food, then tap Analyze meal."
            } else {
                analysisState = .needsReview
                analysisNotes = reviewStatusText
            }
            return
        }

        guard let mealEntryRepository else {
            analysisState = .saved
            return
        }

        let capturedAt = Date()
        let entry = MealEntry(
            loggedAt: capturedAt,
            mealType: draft.mealType,
            notes: draft.trimmedNotes.isEmpty ? nil : draft.trimmedNotes,
            photoMetadata: selectedPhoto.map {
                PhotoMetadata(
                    storageIdentifier: "meal-photo-\(UUID().uuidString)",
                    capturedAt: capturedAt,
                    imageData: $0.jpegData(compressionQuality: 0.85)
                )
            },
            items: draft.detectedFoods.map {
                MealItem(
                    name: $0.name,
                    quantity: $0.estimatedWeightGrams,
                    unit: "g",
                    nutrition: $0.nutrition
                )
            },
            nutrition: nutritionTotals
        )

        do {
            try await mealEntryRepository.saveMealEntry(entry)
            analysisState = .saved
            await loadTodayMeals()
        } catch {
            analysisState = .failed("Meal could not be saved locally. Try again.")
        }
    }

    func loadTodayMeals() async {
        guard let mealEntryRepository else {
            todaySavedMeals = []
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now

        do {
            todaySavedMeals = try await mealEntryRepository.fetchMealEntries(
                in: DateInterval(start: start, end: end)
            )
        } catch {
            todaySavedMeals = []
        }
    }

    private func updateDraft(_ mutation: (inout MealLoggingDraft) -> Void) {
        mutation(&draft)
    }
}

struct MealPhotoDayGroup: Identifiable, Hashable, Sendable {
    let day: Date
    let entries: [MealEntry]

    var id: Date { day }

    var photoEntries: [MealEntry] {
        entries.filter { $0.photoMetadata != nil }
    }

    var nutrition: NutritionAmounts {
        entries.reduce(into: NutritionAmounts()) { totals, entry in
            totals.calories += entry.nutrition.calories
            totals.proteinGrams += entry.nutrition.proteinGrams
            totals.carbohydrateGrams += entry.nutrition.carbohydrateGrams
            totals.fatGrams += entry.nutrition.fatGrams
            totals.fiberGrams += entry.nutrition.fiberGrams
        }
    }
}

@MainActor
final class MealHistoryViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var entries: [MealEntry] = []
    @Published private(set) var loadState: LoadState = .idle

    private let mealEntryRepository: any MealEntryRepository

    init(mealEntryRepository: any MealEntryRepository) {
        self.mealEntryRepository = mealEntryRepository
    }

    var dayGroups: [MealPhotoDayGroup] {
        let calendar = Calendar.current
        return Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.loggedAt)
        }
        .map { MealPhotoDayGroup(day: $0.key, entries: $0.value.sorted { $0.loggedAt > $1.loggedAt }) }
        .filter { !$0.photoEntries.isEmpty }
        .sorted { $0.day > $1.day }
    }

    func loadHistory() async {
        loadState = .loading

        do {
            entries = try await mealEntryRepository.fetchMealEntries(
                in: DateInterval(start: .distantPast, end: .distantFuture)
            )
            loadState = .loaded
        } catch {
            entries = []
            loadState = .failed("Saved meal history could not be loaded right now.")
        }
    }

    func deleteMealPhotoDay(_ day: Date) async {
        let calendar = Calendar.current
        let entriesForDay = entries.filter {
            calendar.isDate($0.loggedAt, inSameDayAs: day) && $0.photoMetadata != nil
        }
        guard !entriesForDay.isEmpty else {
            return
        }

        do {
            for entry in entriesForDay {
                try await mealEntryRepository.deleteMealEntry(id: entry.id)
            }

            entries.removeAll { entry in
                calendar.isDate(entry.loggedAt, inSameDayAs: day) && entry.photoMetadata != nil
            }
        } catch {
            loadState = .failed("Unable to delete that day's meal photos right now.")
        }
    }
}
