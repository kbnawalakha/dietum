import Foundation
import SwiftData

struct MealExportSnapshot: Codable, Hashable, Sendable {
    var createdAt: Date
    var appName: String
    var mealDraft: MealExportDraftPayload?
    var mealEntries: [MealExportMealEntryPayload]
    var reminderSchedules: [MealExportReminderPayload]
    var detectedFoods: [MealExportDetectedFoodPayload]
    var analysisNotes: String?
    var reminderSummaryText: String

    init(
        createdAt: Date = .now,
        appName: String = "Dietum",
        mealDraft: MealExportDraftPayload? = nil,
        mealEntries: [MealExportMealEntryPayload] = [],
        reminderSchedules: [MealExportReminderPayload] = [],
        detectedFoods: [MealExportDetectedFoodPayload] = [],
        analysisNotes: String? = nil,
        reminderSummaryText: String = "Meal reminders are configured locally."
    ) {
        self.createdAt = createdAt
        self.appName = appName
        self.mealDraft = mealDraft
        self.mealEntries = mealEntries
        self.reminderSchedules = reminderSchedules
        self.detectedFoods = detectedFoods
        self.analysisNotes = analysisNotes
        self.reminderSummaryText = reminderSummaryText
    }
}

struct MealExportMealEntryPayload: Codable, Hashable, Sendable {
    var id: UUID
    var loggedAt: Date
    var mealTypeRawValue: String
    var title: String?
    var notes: String?
    var items: [MealExportMealItemPayload]
    var nutrition: MealExportNutritionPayload

    init(entry: MealEntry) {
        self.id = entry.id
        self.loggedAt = entry.loggedAt
        self.mealTypeRawValue = entry.mealType.rawValue
        self.title = entry.title
        self.notes = entry.notes
        self.items = entry.items.map(MealExportMealItemPayload.init)
        self.nutrition = MealExportNutritionPayload(amounts: entry.nutrition)
    }
}

struct MealExportMealItemPayload: Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var quantity: Double?
    var unit: String?
    var nutrition: MealExportNutritionPayload

    init(item: MealItem) {
        self.id = item.id
        self.name = item.name
        self.quantity = item.quantity
        self.unit = item.unit
        self.nutrition = MealExportNutritionPayload(amounts: item.nutrition)
    }
}

struct MealExportNutritionPayload: Codable, Hashable, Sendable {
    var calories: Int
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var fiberGrams: Double

    init(amounts: NutritionAmounts) {
        self.calories = amounts.calories
        self.proteinGrams = amounts.proteinGrams
        self.carbohydrateGrams = amounts.carbohydrateGrams
        self.fatGrams = amounts.fatGrams
        self.fiberGrams = amounts.fiberGrams
    }
}

struct MealExportDraftPayload: Codable, Hashable, Sendable {
    var mealTypeRawValue: String
    var notes: String
    var photoDescription: String

    init(mealType: MealType, notes: String, photoDescription: String) {
        self.mealTypeRawValue = mealType.rawValue
        self.notes = notes
        self.photoDescription = photoDescription
    }
}

struct MealExportReminderPayload: Codable, Hashable, Sendable {
    var mealTypeRawValue: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    init(schedule: MealReminderSchedule) {
        self.mealTypeRawValue = schedule.mealType.rawValue
        self.hour = schedule.time.hour ?? 0
        self.minute = schedule.time.minute ?? 0
        self.isEnabled = schedule.isEnabled
    }
}

struct MealExportDetectedFoodPayload: Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var confidence: Double?

    init(food: DetectedMealFood) {
        self.id = food.id
        self.name = food.name
        self.confidence = food.confidence
    }

    init(item: MealItem) {
        self.id = item.id
        self.name = item.name
        self.confidence = nil
    }
}

enum MealExportError: Error, Equatable {
    case noDataToExport
    case couldNotLoadLocalData
    case couldNotEncode
    case couldNotWriteFile

    var userMessage: String {
        switch self {
        case .noDataToExport:
            return "There is no meal data ready to export yet."
        case .couldNotLoadLocalData:
            return "Dietum could not read the local meal data for export."
        case .couldNotEncode:
            return "Dietum could not prepare the local export file."
        case .couldNotWriteFile:
            return "Dietum could not write the export file to the device."
        }
    }
}

protocol MealExportSnapshotProviding: Sendable {
    @MainActor
    func loadSnapshot() async throws -> MealExportSnapshot
}

@MainActor
final class SwiftDataMealExportSnapshotProvider: MealExportSnapshotProviding {
    private let modelContainer: ModelContainer?
    private let mealEntryRepository: (any MealEntryRepository)?

    init(mealEntryRepository: (any MealEntryRepository)? = nil) {
        if let mealEntryRepository {
            self.modelContainer = nil
            self.mealEntryRepository = mealEntryRepository
            return
        }

        do {
            let container = try DietumPersistenceStack.makeContainer()
            self.modelContainer = container
            self.mealEntryRepository = SwiftDataMealEntryRepository(modelContext: container.mainContext)
        } catch {
            self.modelContainer = nil
            self.mealEntryRepository = nil
        }
    }

    func loadSnapshot() async throws -> MealExportSnapshot {
        guard let mealEntryRepository else {
            throw MealExportError.couldNotLoadLocalData
        }

        do {
            let entries = try await mealEntryRepository.fetchMealEntries(
                in: DateInterval(start: .distantPast, end: .distantFuture)
            )
            let latestEntry = entries.first

            return MealExportSnapshot(
                mealDraft: latestEntry.map {
                    MealExportDraftPayload(
                        mealType: $0.mealType,
                        notes: $0.notes ?? "",
                        photoDescription: $0.photoMetadata == nil ? "No local photo attached" : "Local photo reference"
                    )
                },
                mealEntries: entries.map(MealExportMealEntryPayload.init),
                detectedFoods: latestEntry?.items.map(MealExportDetectedFoodPayload.init) ?? [],
                analysisNotes: latestEntry == nil ? nil : "Foods reflect locally saved meal items; detection confidence was not persisted.",
                reminderSummaryText: "Meal reminder schedules are not persisted in the current local data store."
            )
        } catch {
            throw MealExportError.couldNotLoadLocalData
        }
    }
}

struct StaticMealExportSnapshotProvider: MealExportSnapshotProviding {
    let snapshot: MealExportSnapshot

    @MainActor
    func loadSnapshot() async throws -> MealExportSnapshot {
        snapshot
    }
}

protocol MealExportServicing: Sendable {
    func export(snapshot: MealExportSnapshot) throws -> MealExportResult
}

struct MealExportResult: Hashable, Sendable {
    var fileURL: URL
    var fileName: String
    var byteCount: Int
    var summaryText: String
}

struct MealLocalExportService: MealExportServicing, @unchecked Sendable {
    private let fileManager: FileManager
    private let encoder: JSONEncoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func export(snapshot: MealExportSnapshot) throws -> MealExportResult {
        guard hasExportableContent(snapshot) else {
            throw MealExportError.noDataToExport
        }

        let data: Data
        do {
            data = try encoder.encode(snapshot)
        } catch {
            throw MealExportError.couldNotEncode
        }

        let fileName = "dietum-meal-export-\(Self.timestampFormatter.string(from: snapshot.createdAt)).json"
        let directory = fileManager.temporaryDirectory.appendingPathComponent("DietumExports", isDirectory: true)
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw MealExportError.couldNotWriteFile
        }

        return MealExportResult(
            fileURL: fileURL,
            fileName: fileName,
            byteCount: data.count,
            summaryText: "Export saved locally. You can share the file from this device only."
        )
    }

    private func hasExportableContent(_ snapshot: MealExportSnapshot) -> Bool {
        snapshot.mealDraft != nil
            || !snapshot.mealEntries.isEmpty
            || !snapshot.reminderSchedules.isEmpty
            || !snapshot.detectedFoods.isEmpty
            || !(snapshot.analysisNotes ?? "").isEmpty
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
