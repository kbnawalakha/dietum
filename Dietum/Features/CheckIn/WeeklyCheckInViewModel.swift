import Foundation
import SwiftUI

@MainActor
final class WeeklyCheckInViewModel: ObservableObject {
    enum SaveState: Equatable {
        case idle
        case loading
        case saved(Date)
        case failed(String)
    }

    @Published var draft: CheckInDraft
    @Published var recentLogs: [WeightLog] = []
    @Published var saveState: SaveState = .idle
    @Published private(set) var validationState: CheckInValidationState

    private let weightLogRepository: any WeightLogRepository

    init(weightLogRepository: any WeightLogRepository, draft: CheckInDraft = CheckInDraft()) {
        self.weightLogRepository = weightLogRepository
        self.draft = draft
        self.validationState = CheckInDraftValidator.validate(draft)
    }

    func loadSummary() async {
        await refreshLogs()
    }

    func saveCheckIn() async {
        let validation = validateDraft()
        guard validation.isValid, let weight = parsedWeeklyWeight else {
            saveState = .failed(validation.primaryIssue?.message ?? "Enter today's weight using numbers only.")
            return
        }

        saveState = .loading

        do {
            let notes = makeCombinedNotes()
            let log = WeightLog(
                recordedAt: .now,
                weightKilograms: weight,
                notes: notes.isEmpty ? nil : notes
            )
            try await weightLogRepository.saveWeightLog(log)
            resetDraft()
            await refreshLogs()
            saveState = .saved(Date())
        } catch {
            saveState = .failed("Unable to save today's weight right now.")
        }
    }

    var headline: String {
        switch recentLogs.count {
        case 0:
            return "Confirm today's weight and add optional notes before saving locally."
        case 1:
            return "Today's weight is stored locally. Keep checking in daily to build a useful trend."
        default:
            return "You have \(recentLogs.count) recent daily weight entries stored locally."
        }
    }

    var summaryText: String {
        guard let latest = recentLogs.first else {
            return "No weekly entries yet. Start with your current weight and a short note."
        }

        if let previous = recentLogs.dropFirst().first {
            let delta = latest.weightKilograms - previous.weightKilograms
            let formattedDelta = String(format: "%.1f", abs(delta))
            let direction = delta > 0 ? "up" : delta < 0 ? "down" : "flat"
            return "Latest entry is \(formattedDelta) kg \(direction) from the prior check-in."
        }

        return "Latest entry: \(String(format: "%.1f", latest.weightKilograms)) kg."
    }

    var latestWeightText: String {
        guard let latest = recentLogs.first else { return "—" }
        return String(format: "%.1f kg", latest.weightKilograms)
    }

    var trendText: String {
        guard recentLogs.count > 1, let latest = recentLogs.first, let older = recentLogs.dropFirst().first else {
            return "Stable"
        }

        let delta = latest.weightKilograms - older.weightKilograms
        if abs(delta) < 0.1 {
            return "Stable"
        }

        let formattedDelta = String(format: "%.1f kg", abs(delta))
        return delta > 0 ? "Up \(formattedDelta)" : "Down \(formattedDelta)"
    }

    var saveButtonTitle: String {
        switch saveState {
        case .loading:
            return "Saving..."
        case .saved:
            return "Saved locally"
        case .failed:
            return "Try again"
        case .idle:
            return "Save today's weight"
        }
    }

    var saveButtonSystemImage: String {
        switch saveState {
        case .saved:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        default:
            return "tray.and.arrow.down.fill"
        }
    }

    var canSave: Bool {
        validationState.isValid && saveState != .loading
    }

    var formattedStatus: String? {
        switch saveState {
        case .saved(let date):
            return "Saved \(date.formatted(date: .abbreviated, time: .shortened))"
        case .failed(let message):
            return message
        case .idle, .loading:
            return nil
        }
    }

    private func refreshLogs() async {
        do {
            let start = Calendar.current.date(byAdding: .day, value: -28, to: .now) ?? .now
            let window = DateInterval(start: start, end: .now)
            recentLogs = try await weightLogRepository.fetchWeightLogs(in: window)
                .sorted { $0.recordedAt > $1.recordedAt }
        } catch {
            recentLogs = []
        }
    }

    private func makeCombinedNotes() -> String {
        [
            draft.trimmedEnergyNotes.isEmpty ? nil : "Energy: \(draft.energyNotes)",
            draft.trimmedHungerNotes.isEmpty ? nil : "Hunger: \(draft.hungerNotes)",
            draft.trimmedTrainingNotes.isEmpty ? nil : "Training: \(draft.trainingNotes)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    var noteSummaryText: String {
        switch draft.noteCount {
        case 0:
            return "Add energy, hunger, or training notes to explain the trend."
        case 1:
            return "One note captured to support the weekly weight entry."
        default:
            return "\(draft.noteCount) notes captured to support the weekly weight entry."
        }
    }

    var recentLogSummaryText: String {
        guard let latest = recentLogs.first else {
            return "No weekly entries yet. Start with your current weight and a short note."
        }

        if let previous = recentLogs.dropFirst().first {
            let delta = latest.weightKilograms - previous.weightKilograms
            let formattedDelta = String(format: "%.1f", abs(delta))
            let direction = delta > 0 ? "up" : delta < 0 ? "down" : "flat"
            return "Latest entry is \(formattedDelta) kg \(direction) from the prior check-in."
        }

        return "Latest entry: \(String(format: "%.1f", latest.weightKilograms)) kg."
    }

    var recentLogCards: [WeeklyCheckInLogCard] {
        recentLogs.prefix(3).map { log in
            let noteText = log.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
            return WeeklyCheckInLogCard(
                dateText: log.recordedAt.formatted(date: .abbreviated, time: .omitted),
                weightText: String(format: "%.1f kg", log.weightKilograms),
                noteText: (noteText?.isEmpty == false ? noteText : nil) ?? "No notes added",
                symbolName: "scalemass"
            )
        }
    }

    var validationMessage: String {
        validationState.primaryIssue?.message ?? validationState.summaryText
    }

    func updateDraft(_ mutation: (inout CheckInDraft) -> Void) {
        mutation(&draft)
        validationState = CheckInDraftValidator.validate(draft)
    }

    func resetDraft() {
        updateDraft { draft in
            draft = CheckInDraft()
        }
    }

    func validateDraft() -> CheckInValidationState {
        validationState = CheckInDraftValidator.validate(draft)
        return validationState
    }

    private var parsedWeeklyWeight: Double? {
        Double(draft.trimmedWeeklyWeight.replacingOccurrences(of: ",", with: "."))
    }
}

struct WeeklyCheckInLogCard: Identifiable, Hashable, Sendable {
    var id = UUID()
    var dateText: String
    var weightText: String
    var noteText: String
    var symbolName: String
}
