import Foundation

struct MockMealFoodDetectionService: MealFoodDetectionService {
    func detectFoods(in photo: PhotoMetadata) async throws -> MealFoodDetectionResult {
        try await Task.sleep(nanoseconds: 650_000_000)

        switch photo.storageIdentifier {
        case "meal-photo-breakfast":
            return MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(name: "Greek yogurt", confidence: 0.95),
                    DetectedMealFood(name: "Blueberries", confidence: 0.89),
                    DetectedMealFood(name: "Granola", confidence: 0.84)
                ],
                notes: "Mock analysis found a balanced breakfast sample."
            )
        case "meal-photo-dinner":
            return MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(name: "Salmon", confidence: 0.96),
                    DetectedMealFood(name: "Sweet potato", confidence: 0.91),
                    DetectedMealFood(name: "Broccoli", confidence: 0.87)
                ],
                notes: "Mock analysis found a higher-protein dinner sample."
            )
        default:
            return MealFoodDetectionResult(
                detectedFoods: Self.defaultFoods,
                notes: "Mock analysis created from local sample meal data for the first pass."
            )
        }
    }
}

private extension MockMealFoodDetectionService {
    static var defaultFoods: [DetectedMealFood] {
        [
            DetectedMealFood(name: "Grilled chicken", confidence: 0.94),
            DetectedMealFood(name: "Rice", confidence: 0.89),
            DetectedMealFood(name: "Roasted vegetables", confidence: 0.86)
        ]
    }
}
