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
    var servingSizeGrams: Double?
    var servings: Double
    var nutritionPer100Grams: NutritionAmounts
    var nutrition: NutritionAmounts

    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double? = nil,
        estimatedWeightGrams: Double = 100,
        servingSizeGrams: Double? = nil,
        servings: Double = 1,
        nutritionPer100Grams: NutritionAmounts? = nil,
        nutrition: NutritionAmounts = NutritionAmounts()
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.estimatedWeightGrams = estimatedWeightGrams
        self.servingSizeGrams = servingSizeGrams
        self.servings = servings
        self.nutritionPer100Grams = nutritionPer100Grams ?? nutrition
        self.nutrition = nutrition
    }

    init(
        id: UUID = UUID(),
        name: String,
        confidence: Double? = nil,
        estimatedWeightGrams: Double,
        servingSizeGrams: Double? = nil,
        servings: Double = 1,
        nutritionPer100Grams: NutritionAmounts
    ) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.estimatedWeightGrams = estimatedWeightGrams
        self.servingSizeGrams = servingSizeGrams
        self.servings = servings
        self.nutritionPer100Grams = nutritionPer100Grams
        self.nutrition = nutritionPer100Grams.scaled(toGrams: estimatedWeightGrams)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case confidence
        case estimatedWeightGrams
        case servingSizeGrams
        case servings
        case nutritionPer100Grams
        case nutrition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        estimatedWeightGrams = try container.decodeIfPresent(Double.self, forKey: .estimatedWeightGrams) ?? 100
        servingSizeGrams = try container.decodeIfPresent(Double.self, forKey: .servingSizeGrams)
        servings = try container.decodeIfPresent(Double.self, forKey: .servings) ?? 1
        nutritionPer100Grams = try container.decodeIfPresent(NutritionAmounts.self, forKey: .nutritionPer100Grams) ?? NutritionAmounts()
        nutrition = try container.decodeIfPresent(NutritionAmounts.self, forKey: .nutrition) ?? nutritionPer100Grams.scaled(toGrams: estimatedWeightGrams)
    }
}

protocol MealFoodDetectionService: Sendable {
    func analyzeMeal(description: String, photo: PhotoMetadata?) async throws -> MealFoodDetectionResult
}
