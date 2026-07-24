import Foundation
import SwiftData

@Model
final class StoredMealEntry {
    @Attribute(.unique) var id: UUID
    var loggedAt: Date
    var mealTypeRawValue: String
    var title: String?
    var notes: String?
    var photoMetadataData: Data?
    var itemsData: Data
    var nutritionCalories: Int
    var nutritionProteinGrams: Double
    var nutritionCarbohydrateGrams: Double
    var nutritionFatGrams: Double
    var nutritionFiberGrams: Double

    init(_ entry: MealEntry) {
        self.id = entry.id
        self.loggedAt = entry.loggedAt
        self.mealTypeRawValue = entry.mealType.rawValue
        self.title = entry.title
        self.notes = entry.notes
        self.photoMetadataData = Self.encode(entry.photoMetadata)
        self.itemsData = Self.encode(entry.items) ?? Data()
        self.nutritionCalories = entry.nutrition.calories
        self.nutritionProteinGrams = entry.nutrition.proteinGrams
        self.nutritionCarbohydrateGrams = entry.nutrition.carbohydrateGrams
        self.nutritionFatGrams = entry.nutrition.fatGrams
        self.nutritionFiberGrams = entry.nutrition.fiberGrams
    }

    var mealEntry: MealEntry {
        MealEntry(
            id: id,
            loggedAt: loggedAt,
            mealType: MealType(rawValue: mealTypeRawValue) ?? .custom,
            title: title,
            notes: notes,
            photoMetadata: Self.decode(PhotoMetadata.self, from: photoMetadataData),
            items: Self.decode([MealItem].self, from: itemsData) ?? [],
            nutrition: NutritionAmounts(
                calories: nutritionCalories,
                proteinGrams: nutritionProteinGrams,
                carbohydrateGrams: nutritionCarbohydrateGrams,
                fatGrams: nutritionFatGrams,
                fiberGrams: nutritionFiberGrams
            )
        )
    }
}

private extension StoredMealEntry {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }
}
