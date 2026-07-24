import Foundation
import SwiftData

@Model
final class StoredWeightEntry {
    @Attribute(.unique) var id: UUID
    var recordedAt: Date
    var weightKilograms: Double
    var note: String?

    init(
        id: UUID = UUID(),
        recordedAt: Date = .now,
        weightKilograms: Double = 0,
        note: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.weightKilograms = weightKilograms
        self.note = note
    }

    var weightLog: WeightLog {
        WeightLog(
            id: id,
            recordedAt: recordedAt,
            weightKilograms: weightKilograms,
            notes: note
        )
    }
}
