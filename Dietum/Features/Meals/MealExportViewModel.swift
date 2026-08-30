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

    enum LocalDataState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var exportState: ExportState = .idle
    @Published var localDataState: LocalDataState = .idle
    @Published var includeDetectedFoods: Bool
    @Published var includeMealDraft: Bool
    @Published var includeReminderSchedules: Bool
    @Published var exportSummaryText: String

    private let exportService: MealExportServicing
    private let snapshotProvider: any MealExportSnapshotProviding
    private var localSnapshot = MealExportSnapshot()

    init(
        exportService: MealExportServicing = MealLocalExportService(),
        snapshotProvider: any MealExportSnapshotProviding = SwiftDataMealExportSnapshotProvider(),
        includeDetectedFoods: Bool = true,
        includeMealDraft: Bool = true,
        includeReminderSchedules: Bool = true,
        exportSummaryText: String = "Export only creates a local file on this device. Nothing is sent to a server."
    ) {
        self.exportService = exportService
        self.snapshotProvider = snapshotProvider
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
        exportState == .exporting || localDataState != .loaded
    }

    var localDataStatusText: String {
        switch localDataState {
        case .idle:
            return "Waiting to read local meal data."
        case .loading:
            return "Reading local meal data..."
        case .loaded:
            let count = localSnapshot.mealEntries.count
            return "Loaded \(count) saved meal entr\(count == 1 ? "y" : "ies") from this device."
        case .failed(let message):
            return message
        }
    }

    func loadLocalData() async {
        guard localDataState != .loading else {
            return
        }

        localDataState = .loading

        do {
            localSnapshot = try await snapshotProvider.loadSnapshot()
            localDataState = .loaded
        } catch let error as MealExportError {
            localDataState = .failed(error.userMessage)
        } catch {
            localDataState = .failed(MealExportError.couldNotLoadLocalData.userMessage)
        }
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
            createdAt: localSnapshot.createdAt,
            appName: localSnapshot.appName,
            mealDraft: includeMealDraft ? localSnapshot.mealDraft : nil,
            mealEntries: includeMealDraft ? localSnapshot.mealEntries : [],
            reminderSchedules: includeReminderSchedules ? localSnapshot.reminderSchedules : [],
            detectedFoods: includeDetectedFoods ? localSnapshot.detectedFoods : [],
            analysisNotes: includeDetectedFoods ? localSnapshot.analysisNotes : nil,
            reminderSummaryText: localSnapshot.reminderSummaryText
        )
    }
}
