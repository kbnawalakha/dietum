import Foundation
import SwiftData

@MainActor
final class SwiftDataWeightEntryRepository: WeightLogRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchWeightLogs(in dateInterval: DateInterval) async throws -> [WeightLog] {
        let entries = try modelContext.fetch(FetchDescriptor<StoredWeightEntry>())
        return entries
            .map(\.weightLog)
            .filter { dateInterval.contains($0.recordedAt) }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    func saveWeightLog(_ log: WeightLog) async throws {
        let existingEntries = try modelContext.fetch(FetchDescriptor<StoredWeightEntry>())
        existingEntries
            .filter { $0.id == log.id }
            .forEach { modelContext.delete($0) }

        modelContext.insert(
            StoredWeightEntry(
                id: log.id,
                recordedAt: log.recordedAt,
                weightKilograms: log.weightKilograms,
                note: log.notes
            )
        )
        try modelContext.save()
    }

    func deleteWeightLog(id: WeightLog.ID) async throws {
        let existingEntries = try modelContext.fetch(FetchDescriptor<StoredWeightEntry>())
        existingEntries
            .filter { $0.id == id }
            .forEach { modelContext.delete($0) }

        try modelContext.save()
    }
}
