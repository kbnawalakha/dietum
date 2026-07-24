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

    @Published var weeklyWeight: String = ""
    @Published var energyNotes: String = ""
    @Published var hungerNotes: String = ""
    @Published var trainingNotes: String = ""
    @Published var recentLogs: [WeightLog] = []
    @Published var saveState: SaveState = .idle

    private let weightLogRepository: any WeightLogRepository

    init(weightLogRepository: any WeightLogRepository) {
        self.weightLogRepository = weightLogRepository
    }

    func loadSummary() async {
        await refreshLogs()
    }

    func saveCheckIn() async {
        guard let weight = Double(weeklyWeight.replacingOccurrences(of: ",", with: ".")) else {
            saveState = .failed("Enter your weekly weight using numbers only.")
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
            weeklyWeight = ""
            energyNotes = ""
            hungerNotes = ""
            trainingNotes = ""
            await refreshLogs()
            saveState = .saved(Date())
        } catch {
            saveState = .failed("Unable to save the weekly check-in right now.")
        }
    }

    var headline: String {
        switch recentLogs.count {
        case 0:
            return "Review the week, confirm your current weight, and add notes before saving locally."
        case 1:
            return "One weekly check-in is stored locally. Add another to make the trend more useful."
        default:
            return "You have \(recentLogs.count) weekly entries stored locally."
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
            return "Save weekly check-in"
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
        Double(weeklyWeight.replacingOccurrences(of: ",", with: ".")) != nil && saveState != .loading
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
            energyNotes.isEmpty ? nil : "Energy: \(energyNotes)",
            hungerNotes.isEmpty ? nil : "Hunger: \(hungerNotes)",
            trainingNotes.isEmpty ? nil : "Training: \(trainingNotes)"
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }
}
