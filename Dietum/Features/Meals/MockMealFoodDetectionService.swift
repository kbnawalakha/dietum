import Foundation

struct MockMealFoodDetectionService: MealFoodDetectionService {
    func detectFoods(in photo: PhotoMetadata) async throws -> MealFoodDetectionResult {
        try await Task.sleep(nanoseconds: 650_000_000)

        return MealFoodDetectionResult(
            detectedFoods: [
                DetectedMealFood(name: "Grilled chicken", confidence: 0.94),
                DetectedMealFood(name: "Rice", confidence: 0.89),
                DetectedMealFood(name: "Roasted vegetables", confidence: 0.86)
            ],
            notes: "Mock analysis created from local sample meal data for the first pass."
        )
    }
}

