import Foundation
import SwiftData

enum SwiftDataMealEntryRepositoryError: Error, Equatable {
    case invalidDateInterval
}

@MainActor
final class SwiftDataMealEntryRepository: MealEntryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchMealEntries(in dateInterval: DateInterval) async throws -> [MealEntry] {
        guard dateInterval.start <= dateInterval.end else {
            throw SwiftDataMealEntryRepositoryError.invalidDateInterval
        }

        let entries = try modelContext.fetch(FetchDescriptor<StoredMealEntry>())
        return entries
            .map(\.mealEntry)
            .filter { dateInterval.contains($0.loggedAt) }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func saveMealEntry(_ entry: MealEntry) async throws {
        let existingEntries = try modelContext.fetch(FetchDescriptor<StoredMealEntry>())
        if let storedEntry = existingEntries.first(where: { $0.id == entry.id }) {
            storedEntry.loggedAt = entry.loggedAt
            storedEntry.mealTypeRawValue = entry.mealType.rawValue
            storedEntry.title = entry.title
            storedEntry.notes = entry.notes
            storedEntry.photoMetadataData = MealEntryPersistenceMapper.encode(entry.photoMetadata)
            storedEntry.itemsData = MealEntryPersistenceMapper.encode(entry.items) ?? Data()
            storedEntry.nutritionCalories = entry.nutrition.calories
            storedEntry.nutritionProteinGrams = entry.nutrition.proteinGrams
            storedEntry.nutritionCarbohydrateGrams = entry.nutrition.carbohydrateGrams
            storedEntry.nutritionFatGrams = entry.nutrition.fatGrams
            storedEntry.nutritionFiberGrams = entry.nutrition.fiberGrams
        } else {
            modelContext.insert(StoredMealEntry(entry))
        }
        try modelContext.save()
    }

    func deleteMealEntry(id: MealEntry.ID) async throws {
        let existingEntries = try modelContext.fetch(FetchDescriptor<StoredMealEntry>())
        existingEntries
            .filter { $0.id == id }
            .forEach { modelContext.delete($0) }

        try modelContext.save()
    }
}
