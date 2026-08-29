import Foundation

struct MealExportSnapshot: Codable, Hashable, Sendable {
    var createdAt: Date
    var appName: String
    var mealDraft: MealExportDraftPayload?
    var reminderSchedules: [MealExportReminderPayload]
    var detectedFoods: [MealExportDetectedFoodPayload]
    var analysisNotes: String?
    var reminderSummaryText: String

    init(
        createdAt: Date = .now,
        appName: String = "Dietum",
        mealDraft: MealExportDraftPayload? = nil,
        reminderSchedules: [MealExportReminderPayload] = [],
        detectedFoods: [MealExportDetectedFoodPayload] = [],
        analysisNotes: String? = nil,
        reminderSummaryText: String = "Meal reminders are configured locally."
    ) {
        self.createdAt = createdAt
        self.appName = appName
        self.mealDraft = mealDraft
        self.reminderSchedules = reminderSchedules
        self.detectedFoods = detectedFoods
        self.analysisNotes = analysisNotes
        self.reminderSummaryText = reminderSummaryText
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
}

enum MealExportError: Error, Equatable {
    case noDataToExport
    case couldNotEncode
    case couldNotWriteFile

    var userMessage: String {
        switch self {
        case .noDataToExport:
            return "There is no meal data ready to export yet."
        case .couldNotEncode:
            return "Dietum could not prepare the local export file."
        case .couldNotWriteFile:
            return "Dietum could not write the export file to the device."
        }
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
