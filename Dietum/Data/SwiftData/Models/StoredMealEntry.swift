import Foundation
import SwiftData

enum MealEntryPersistenceMapper {
    static func makeMealEntry(from stored: StoredMealEntry) -> MealEntry {
        MealEntry(
            id: stored.id,
            loggedAt: stored.loggedAt,
            mealType: MealType(rawValue: stored.mealTypeRawValue) ?? .custom,
            title: stored.title,
            notes: stored.notes,
            photoMetadata: decode(PhotoMetadata.self, from: stored.photoMetadataData),
            items: decode([MealItem].self, from: stored.itemsData) ?? [],
            nutrition: NutritionAmounts(
                calories: stored.nutritionCalories,
                proteinGrams: stored.nutritionProteinGrams,
                carbohydrateGrams: stored.nutritionCarbohydrateGrams,
                fatGrams: stored.nutritionFatGrams,
                fiberGrams: stored.nutritionFiberGrams
            )
        )
    }

    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

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
        self.photoMetadataData = MealEntryPersistenceMapper.encode(entry.photoMetadata)
        self.itemsData = MealEntryPersistenceMapper.encode(entry.items) ?? Data()
        self.nutritionCalories = entry.nutrition.calories
        self.nutritionProteinGrams = entry.nutrition.proteinGrams
        self.nutritionCarbohydrateGrams = entry.nutrition.carbohydrateGrams
        self.nutritionFatGrams = entry.nutrition.fatGrams
        self.nutritionFiberGrams = entry.nutrition.fiberGrams
    }

    var mealEntry: MealEntry {
        MealEntryPersistenceMapper.makeMealEntry(from: self)
    }
}
