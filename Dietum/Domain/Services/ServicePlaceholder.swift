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
    var estimatedWeightGrams: Double
    var nutritionPer100Grams: NutritionAmounts
    var nutrition: NutritionAmounts

    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double? = nil,
        estimatedWeightGrams: Double = 100,
        nutritionPer100Grams: NutritionAmounts? = nil,
        nutrition: NutritionAmounts = NutritionAmounts()
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.estimatedWeightGrams = estimatedWeightGrams
        self.nutritionPer100Grams = nutritionPer100Grams ?? nutrition
        self.nutrition = nutrition
    }

    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double? = nil,
        estimatedWeightGrams: Double,
        nutritionPer100Grams: NutritionAmounts
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.estimatedWeightGrams = estimatedWeightGrams
        self.nutritionPer100Grams = nutritionPer100Grams
        self.nutrition = nutritionPer100Grams.scaled(toGrams: estimatedWeightGrams)
    }
}

protocol MealFoodDetectionService: Sendable {
    func analyzeMeal(description: String, photo: PhotoMetadata?) async throws -> MealFoodDetectionResult
}
