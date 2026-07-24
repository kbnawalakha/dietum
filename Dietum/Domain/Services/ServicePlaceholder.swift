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

    init(id: UUID = UUID(), name: String, confidence: Double? = nil) {
        self.id = id
        self.name = name
        self.confidence = confidence
    }
}

protocol MealFoodDetectionService {
    func detectFoods(in photo: PhotoMetadata) async throws -> MealFoodDetectionResult
}
