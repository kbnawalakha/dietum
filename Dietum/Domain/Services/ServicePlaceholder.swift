import Foundation

struct MealFoodDetectionResult: Codable, Hashable, Sendable {
    var detectedFoods: [DetectedMealFood]
    var notes: String?

    init(detectedFoods: [DetectedMealFood] = [], notes: String? = nil) {
        self.detectedFoods = detectedFoods
        self.notes = notes
    }
}

struct DetectedMealFood: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var confidence: Double?
    var nutrition: NutritionAmounts

    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double? = nil,
        nutrition: NutritionAmounts = NutritionAmounts()
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.nutrition = nutrition
    }
}

protocol MealFoodDetectionService: Sendable {
    func analyzeMeal(description: String, photo: PhotoMetadata?) async throws -> MealFoodDetectionResult
}
