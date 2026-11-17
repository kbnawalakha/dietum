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
                            nutrition: NutritionAmounts(
                                calories: 520,
                                proteinGrams: 30,
                                carbohydrateGrams: 55,
                                fatGrams: 18,
                                fiberGrams: 7
                            )
                        )
                    ],
                    notes: "Photo estimate created locally from a general mixed-meal profile. Add a short description of the visible foods for a more specific breakdown, then edit portions before saving."
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
                nutrition: item.nutrition
            )
        }

        guard !foods.isEmpty else {
            return MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(
                        name: "General meal estimate",
                        confidence: 0.35,
                        nutrition: NutritionAmounts(
                            calories: 500,
                            proteinGrams: 25,
                            carbohydrateGrams: 55,
                            fatGrams: 18,
                            fiberGrams: 6
                        )
                    )
                ],
                notes: "Broad local estimate because the description did not match a known ingredient. Edit the food name and macros for a more accurate portion before saving."
            )
        }

        return MealFoodDetectionResult(
            detectedFoods: foods,
            notes: "Local estimate based on the ingredients you described. Review portions and correct any food before saving."
        )
    }
}

private extension LocalMealNutritionAnalysisService {
    struct CatalogItem: Sendable {
        let name: String
        let keywords: [String]
        let nutrition: NutritionAmounts
    }

    static let catalog: [CatalogItem] = [
        CatalogItem(name: "Chicken", keywords: ["chicken"], nutrition: NutritionAmounts(calories: 335, proteinGrams: 62, carbohydrateGrams: 0, fatGrams: 7, fiberGrams: 0)),
        CatalogItem(name: "Salmon", keywords: ["salmon"], nutrition: NutritionAmounts(calories: 367, proteinGrams: 39, carbohydrateGrams: 0, fatGrams: 22, fiberGrams: 0)),
        CatalogItem(name: "Eggs", keywords: ["egg", "eggs"], nutrition: NutritionAmounts(calories: 144, proteinGrams: 13, carbohydrateGrams: 1, fatGrams: 10, fiberGrams: 0)),
        CatalogItem(name: "Rice", keywords: ["rice"], nutrition: NutritionAmounts(calories: 205, proteinGrams: 4, carbohydrateGrams: 45, fatGrams: 0, fiberGrams: 1)),
        CatalogItem(name: "Pasta", keywords: ["pasta", "spaghetti"], nutrition: NutritionAmounts(calories: 220, proteinGrams: 8, carbohydrateGrams: 43, fatGrams: 1, fiberGrams: 3)),
        CatalogItem(name: "Potato", keywords: ["potato", "potatoes"], nutrition: NutritionAmounts(calories: 161, proteinGrams: 4, carbohydrateGrams: 37, fatGrams: 0, fiberGrams: 4)),
        CatalogItem(name: "Broccoli", keywords: ["broccoli"], nutrition: NutritionAmounts(calories: 55, proteinGrams: 4, carbohydrateGrams: 11, fatGrams: 1, fiberGrams: 5)),
        CatalogItem(name: "Vegetables", keywords: ["vegetable", "vegetables", "salad"], nutrition: NutritionAmounts(calories: 80, proteinGrams: 3, carbohydrateGrams: 14, fatGrams: 1, fiberGrams: 5)),
        CatalogItem(name: "Greek yogurt", keywords: ["yogurt", "yoghurt"], nutrition: NutritionAmounts(calories: 130, proteinGrams: 20, carbohydrateGrams: 8, fatGrams: 1, fiberGrams: 0)),
        CatalogItem(name: "Blueberries", keywords: ["blueberry", "blueberries"], nutrition: NutritionAmounts(calories: 84, proteinGrams: 1, carbohydrateGrams: 21, fatGrams: 0, fiberGrams: 4)),
        CatalogItem(name: "Banana", keywords: ["banana"], nutrition: NutritionAmounts(calories: 105, proteinGrams: 1, carbohydrateGrams: 27, fatGrams: 0, fiberGrams: 3)),
        CatalogItem(name: "Avocado", keywords: ["avocado"], nutrition: NutritionAmounts(calories: 240, proteinGrams: 3, carbohydrateGrams: 13, fatGrams: 22, fiberGrams: 10)),
        CatalogItem(name: "Granola", keywords: ["granola"], nutrition: NutritionAmounts(calories: 240, proteinGrams: 6, carbohydrateGrams: 36, fatGrams: 9, fiberGrams: 4)),
        CatalogItem(name: "Bread", keywords: ["bread", "toast"], nutrition: NutritionAmounts(calories: 160, proteinGrams: 6, carbohydrateGrams: 28, fatGrams: 2, fiberGrams: 2)),
        CatalogItem(name: "Beef", keywords: ["beef", "steak"], nutrition: NutritionAmounts(calories: 310, proteinGrams: 38, carbohydrateGrams: 0, fatGrams: 17, fiberGrams: 0))
        ]
    }

typealias MockMealFoodDetectionService = LocalMealNutritionAnalysisService
