import Foundation

struct LocalMealNutritionAnalysisService: MealFoodDetectionService {
    func analyzeMeal(description: String, photo: PhotoMetadata?) async throws -> MealFoodDetectionResult {
        try await Task.sleep(nanoseconds: 650_000_000)

        let normalizedDescription = description
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedDescription.isEmpty else {
            if photo != nil {
                return MealFoodDetectionResult(
                    detectedFoods: [
                        DetectedMealFood(
                            name: "Photo meal estimate",
                            confidence: 0.25,
                            estimatedWeightGrams: 450,
                            nutritionPer100Grams: NutritionAmounts(
                                calories: 116,
                                proteinGrams: 6.7,
                                carbohydrateGrams: 12.2,
                                fatGrams: 4,
                                fiberGrams: 1.6
                            )
                        )
                    ],
                    notes: "Photo estimate uses a general mixed-meal profile because this local build has no food-segmentation model. Add a description and adjust the gram portion before saving."
                )
            }

            return MealFoodDetectionResult(
                detectedFoods: [],
                notes: "Describe the meal before analyzing it. Include broad ingredients such as chicken, rice, vegetables, eggs, or pasta."
            )
        }

        let foods = Self.catalog.filter { item in
            item.keywords.contains { normalizedDescription.contains($0) }
        }.map { item in
            DetectedMealFood(
                name: item.name,
                confidence: 0.9,
                estimatedWeightGrams: item.defaultPortionGrams,
                nutritionPer100Grams: item.nutritionPer100Grams
            )
        }

        guard !foods.isEmpty else {
            return MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(
                        name: "General meal estimate",
                        confidence: 0.35,
                        estimatedWeightGrams: 350,
                        nutritionPer100Grams: NutritionAmounts(
                            calories: 143,
                            proteinGrams: 7.1,
                            carbohydrateGrams: 15.7,
                            fatGrams: 5.1,
                            fiberGrams: 1.7
                        )
                    )
                ],
                notes: "Broad local estimate because the description did not match a known ingredient. Adjust the gram portion and macros for a more accurate result before saving."
            )
        }

        return MealFoodDetectionResult(
            detectedFoods: foods,
            notes: "Local estimate uses cooked/raw nutrition per 100 g and a default portion for each detected food. Review gram portions and correct anything before saving."
        )
    }
}

private extension LocalMealNutritionAnalysisService {
    struct CatalogItem: Sendable {
        let name: String
        let keywords: [String]
        let nutritionPer100Grams: NutritionAmounts
        let defaultPortionGrams: Double
    }

    static let catalog: [CatalogItem] = [
        CatalogItem(name: "Chicken", keywords: ["chicken"], nutritionPer100Grams: NutritionAmounts(calories: 165, proteinGrams: 31, fatGrams: 3.6), defaultPortionGrams: 150),
        CatalogItem(name: "Salmon", keywords: ["salmon"], nutritionPer100Grams: NutritionAmounts(calories: 208, proteinGrams: 20.4, fatGrams: 13.4), defaultPortionGrams: 140),
        CatalogItem(name: "Eggs", keywords: ["egg", "eggs"], nutritionPer100Grams: NutritionAmounts(calories: 143, proteinGrams: 12.6, carbohydrateGrams: 0.7, fatGrams: 9.5), defaultPortionGrams: 100),
        CatalogItem(name: "Rice", keywords: ["rice"], nutritionPer100Grams: NutritionAmounts(calories: 130, proteinGrams: 2.7, carbohydrateGrams: 28.2, fatGrams: 0.3, fiberGrams: 0.4), defaultPortionGrams: 180),
        CatalogItem(name: "Pasta", keywords: ["pasta", "spaghetti"], nutritionPer100Grams: NutritionAmounts(calories: 157, proteinGrams: 5.8, carbohydrateGrams: 30.9, fatGrams: 0.9, fiberGrams: 1.8), defaultPortionGrams: 180),
        CatalogItem(name: "Potato", keywords: ["potato", "potatoes"], nutritionPer100Grams: NutritionAmounts(calories: 93, proteinGrams: 2.5, carbohydrateGrams: 21.2, fatGrams: 0.1, fiberGrams: 2.2), defaultPortionGrams: 180),
        CatalogItem(name: "Broccoli", keywords: ["broccoli"], nutritionPer100Grams: NutritionAmounts(calories: 35, proteinGrams: 2.4, carbohydrateGrams: 7.2, fatGrams: 0.4, fiberGrams: 3.3), defaultPortionGrams: 100),
        CatalogItem(name: "Vegetables", keywords: ["vegetable", "vegetables", "salad"], nutritionPer100Grams: NutritionAmounts(calories: 45, proteinGrams: 2, carbohydrateGrams: 8, fatGrams: 0.5, fiberGrams: 3), defaultPortionGrams: 150),
        CatalogItem(name: "Greek yogurt", keywords: ["yogurt", "yoghurt"], nutritionPer100Grams: NutritionAmounts(calories: 73, proteinGrams: 10, carbohydrateGrams: 3.9, fatGrams: 2), defaultPortionGrams: 170),
        CatalogItem(name: "Blueberries", keywords: ["blueberry", "blueberries"], nutritionPer100Grams: NutritionAmounts(calories: 57, proteinGrams: 0.7, carbohydrateGrams: 14.5, fatGrams: 0.3, fiberGrams: 2.4), defaultPortionGrams: 100),
        CatalogItem(name: "Banana", keywords: ["banana"], nutritionPer100Grams: NutritionAmounts(calories: 89, proteinGrams: 1.1, carbohydrateGrams: 22.8, fatGrams: 0.3, fiberGrams: 2.6), defaultPortionGrams: 118),
        CatalogItem(name: "Avocado", keywords: ["avocado"], nutritionPer100Grams: NutritionAmounts(calories: 160, proteinGrams: 2, carbohydrateGrams: 8.5, fatGrams: 14.7, fiberGrams: 6.7), defaultPortionGrams: 100),
        CatalogItem(name: "Granola", keywords: ["granola"], nutritionPer100Grams: NutritionAmounts(calories: 471, proteinGrams: 10, carbohydrateGrams: 64, fatGrams: 20, fiberGrams: 7), defaultPortionGrams: 45),
        CatalogItem(name: "Bread", keywords: ["bread", "toast"], nutritionPer100Grams: NutritionAmounts(calories: 265, proteinGrams: 9, carbohydrateGrams: 49, fatGrams: 3.2, fiberGrams: 2.7), defaultPortionGrams: 64),
        CatalogItem(name: "Beef", keywords: ["beef", "steak"], nutritionPer100Grams: NutritionAmounts(calories: 217, proteinGrams: 26, fatGrams: 12), defaultPortionGrams: 150)
    ]
    }

typealias MockMealFoodDetectionService = LocalMealNutritionAnalysisService
