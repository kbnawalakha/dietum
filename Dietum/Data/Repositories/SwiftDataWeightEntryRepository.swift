import Foundation
import SwiftData

@MainActor
final class SwiftDataWeightEntryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchRecentEntries(limit: Int = 10) throws -> [StoredWeightEntry] {
        let entries = try modelContext.fetch(FetchDescriptor<StoredWeightEntry>())
        return entries
            .sorted { $0.recordedAt > $1.recordedAt }
            .prefix(limit)
            .map { $0 }
    }

    func addEntry(_ entry: StoredWeightEntry) throws {
        modelContext.insert(entry)
        try modelContext.save()
    }
}
