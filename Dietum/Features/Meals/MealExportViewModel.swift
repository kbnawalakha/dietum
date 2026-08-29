import Foundation
import SwiftUI

@MainActor
final class MealExportViewModel: ObservableObject {
    enum ExportState: Equatable {
        case idle
        case exporting
        case ready(MealExportResult)
        case failed(String)
    }

    @Published var exportState: ExportState = .idle
    @Published var includeDetectedFoods: Bool
    @Published var includeMealDraft: Bool
    @Published var includeReminderSchedules: Bool
    @Published var exportSummaryText: String

    private let exportService: MealExportServicing
    private let mealDraft: MealLoggingDraft
    private let reminderSchedules: [MealReminderSchedule]
    private let detectedFoods: [DetectedMealFood]
    private let analysisNotes: String?

    init(
        exportService: MealExportServicing = MealLocalExportService(),
        mealDraft: MealLoggingDraft = MealLoggingDraft(
            mealType: .dinner,
            notes: "Sample meal captured locally for export."
        ),
        reminderSchedules: [MealReminderSchedule] = [
            MealReminderSchedule(mealType: .breakfast, hour: 8),
            MealReminderSchedule(mealType: .lunch, hour: 13),
            MealReminderSchedule(mealType: .dinner, hour: 19)
        ],
        detectedFoods: [DetectedMealFood] = [
            DetectedMealFood(name: "Salmon", confidence: 0.96),
            DetectedMealFood(name: "Rice", confidence: 0.91),
            DetectedMealFood(name: "Asparagus", confidence: 0.85)
        ],
        analysisNotes: String? = "Sample meal detection output prepared locally for export.",
        includeDetectedFoods: Bool = true,
        includeMealDraft: Bool = true,
        includeReminderSchedules: Bool = true,
        exportSummaryText: String = "Export only creates a local file on this device. Nothing is sent to a server."
    ) {
        self.exportService = exportService
        self.mealDraft = mealDraft
        self.reminderSchedules = reminderSchedules
        self.detectedFoods = detectedFoods
        self.analysisNotes = analysisNotes
        self.includeDetectedFoods = includeDetectedFoods
        self.includeMealDraft = includeMealDraft
        self.includeReminderSchedules = includeReminderSchedules
        self.exportSummaryText = exportSummaryText
    }

    var exportHeadline: String {
        switch exportState {
        case .idle:
            return "Prepare a local export package with meal reminders and meal logging state."
        case .exporting:
            return "Preparing the export locally."
        case .ready:
            return "The export file is ready to share from this device."
        case .failed(let message):
            return message
        }
    }

    var statusText: String {
        switch exportState {
        case .idle:
            return "Not exported yet"
        case .exporting:
            return "Exporting"
        case .ready:
            return "Export ready"
        case .failed:
            return "Export failed"
        }
    }

    var statusSymbolName: String {
        switch exportState {
        case .idle:
            return "square.and.arrow.up"
        case .exporting:
            return "hourglass"
        case .ready:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    var statusDetail: String {
        switch exportState {
        case .idle:
            return "Export is local and user initiated."
        case .exporting:
            return "The JSON file is being prepared on the device."
        case .ready(let result):
            return "\(result.fileName) • \(ByteCountFormatter.string(fromByteCount: Int64(result.byteCount), countStyle: .file))"
        case .failed(let message):
            return message
        }
    }

    var exportButtonDisabled: Bool {
        exportState == .exporting
    }

    func exportLocalData() {
        guard exportState != .exporting else {
            return
        }

        exportState = .exporting

        do {
            let result = try exportService.export(snapshot: snapshot)
            exportState = .ready(result)
        } catch let error as MealExportError {
            exportState = .failed(error.userMessage)
        } catch {
            exportState = .failed("Dietum could not finish the local export.")
        }
    }

    func reset() {
        exportState = .idle
    }

    private var snapshot: MealExportSnapshot {
        MealExportSnapshot(
            mealDraft: includeMealDraft ? MealExportDraftPayload(
                mealType: mealDraft.mealType,
                notes: mealDraft.notes,
                photoDescription: mealDraft.photoDescription
            ) : nil,
            reminderSchedules: includeReminderSchedules ? reminderSchedules.map(MealExportReminderPayload.init) : [],
            detectedFoods: includeDetectedFoods ? detectedFoods.map(MealExportDetectedFoodPayload.init) : [],
            analysisNotes: includeDetectedFoods ? analysisNotes : nil,
            reminderSummaryText: "Meal reminders are configured locally and ready for manual export."
        )
    }
}
