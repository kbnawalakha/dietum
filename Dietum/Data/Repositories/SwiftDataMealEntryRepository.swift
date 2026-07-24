import Foundation
import SwiftData

@MainActor
final class SwiftDataMealEntryRepository: MealEntryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchMealEntries(in dateInterval: DateInterval) async throws -> [MealEntry] {
        let entries = try modelContext.fetch(FetchDescriptor<StoredMealEntry>())
        return entries
            .map(\.mealEntry)
            .filter { dateInterval.contains($0.loggedAt) }
            .sorted { $0.loggedAt > $1.loggedAt }
    }

    func saveMealEntry(_ entry: MealEntry) async throws {
        let existingEntries = try modelContext.fetch(FetchDescriptor<StoredMealEntry>())
        existingEntries
            .filter { $0.id == entry.id }
            .forEach { modelContext.delete($0) }

        modelContext.insert(StoredMealEntry(entry))
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
