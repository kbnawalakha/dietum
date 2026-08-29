import Foundation
import SwiftUI

@MainActor
final class ProgressPhotosViewModel: ObservableObject {
    enum SaveState: Equatable {
        case idle
        case saving
        case saved(Date)
        case failed(String)
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published var notes: String = ""
    @Published var stagedPhotos: [ProgressPhotoAngle: PhotoMetadata] = [:]
    @Published var recentPhotos: [ProgressPhotoMetadata] = []
    @Published var comparisonAngle: ProgressPhotoAngle = .front
    @Published var comparisonBaselineID: UUID?
    @Published var comparisonLatestID: UUID?
    @Published var saveState: SaveState = .idle
    @Published var loadState: LoadState = .idle

    private let progressPhotoRepository: any ProgressPhotoRepository
    private var captureSequence: Int = 0

    init(progressPhotoRepository: any ProgressPhotoRepository = MemoryProgressPhotoRepository()) {
        self.progressPhotoRepository = progressPhotoRepository
    }

    func loadRecentPhotos() async {
        loadState = .loading

        do {
            let start = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
            let window = DateInterval(start: start, end: .now)
            recentPhotos = try await progressPhotoRepository.fetchProgressPhotos(in: window)
            updateComparisonSelection()
            loadState = .loaded
        } catch {
            loadState = .failed("Unable to load progress photos right now.")
            recentPhotos = []
        }
    }

    func stageMockPhoto(for angle: ProgressPhotoAngle) {
        captureSequence += 1
        let storageIdentifier = "progress-photo-\(angle.rawValue)-mock-\(String(format: "%02d", captureSequence))"
        stagedPhotos[angle] = PhotoMetadata(
            storageIdentifier: storageIdentifier,
            capturedAt: .now
        )
        saveState = .idle
    }

    func saveStagedPhotos() async {
        guard !stagedPhotos.isEmpty else {
            saveState = .failed("Stage at least one progress photo before saving.")
            return
        }

        saveState = .saving

        do {
            let noteText = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            for angle in ProgressPhotoAngle.allCases {
                guard let photo = stagedPhotos[angle] else {
                    continue
                }

                let metadata = ProgressPhotoMetadata(
                    capturedAt: photo.capturedAt,
                    angle: angle,
                    photo: photo,
                    notes: noteText.isEmpty ? nil : noteText
                )
                try await progressPhotoRepository.saveProgressPhoto(metadata)
            }

            stagedPhotos.removeAll()
            notes = ""
            saveState = .saved(Date())
            await loadRecentPhotos()
        } catch {
            saveState = .failed("Unable to save the staged progress photos right now.")
        }
    }

    func clearStagedPhotos() {
        stagedPhotos.removeAll()
        notes = ""
        saveState = .idle
    }

    var headline: String {
        switch loadState {
        case .loading:
            return "Loading your local progress-photo history."
        case .failed(let message):
            return message
        case .idle, .loaded:
            return "Stage front, back, left, and right mock photos locally, then save the set."
        }
    }

    var stagedCountText: String {
        if stagedPhotos.isEmpty {
            return "No staged photos yet."
        }

        let count = stagedPhotos.count
        return "\(count) of 4 angles staged."
    }

    var stagedSummaryText: String {
        guard !stagedPhotos.isEmpty else {
            return "Tap any angle card to stage a mock photo for that pose."
        }

        let orderedAngles = stagedPhotos.keys.sorted { angleOrder($0) < angleOrder($1) }
        let names = orderedAngles.map(\.displayName).joined(separator: ", ")
        return "Staged angles: \(names)."
    }

    var comparisonHeadline: String {
        guard let comparisonBaseline, let comparisonLatest else {
            return "Save two \(comparisonAngle.displayName.lowercased()) photos to compare the same pose."
        }

        let days = Calendar.current.dateComponents([.day], from: comparisonBaseline.capturedAt, to: comparisonLatest.capturedAt).day ?? 0
        if days <= 0 {
            return "Your two \(comparisonAngle.displayName.lowercased()) photos were captured on the same day."
        }

        return "Your \(comparisonAngle.displayName.lowercased()) photos are \(days) day\(days == 1 ? "" : "s") apart."
    }

    var comparisonDetail: String {
        guard !recentPhotos.isEmpty else {
            return "Save a local photo set, then repeat an angle to unlock a side-by-side comparison."
        }

        let angleCount = Set(recentPhotos.map(\.angle)).count
        guard comparisonBaseline != nil, comparisonLatest != nil else {
            return "\(angleCount) of 4 angles appear in your local history. Select an angle with two saved entries to compare dates and pose consistently."
        }

        return "Both images remain on this device. Use the same angle and similar lighting for a more useful visual check."
    }

    var comparisonCandidates: [ProgressPhotoMetadata] {
        recentPhotos
            .filter { $0.angle == comparisonAngle }
            .sorted { $0.capturedAt < $1.capturedAt }
    }

    var comparisonBaseline: ProgressPhotoMetadata? {
        comparisonCandidates.first { $0.id == comparisonBaselineID }
    }

    var comparisonLatest: ProgressPhotoMetadata? {
        comparisonCandidates.first { $0.id == comparisonLatestID }
    }

    var comparisonSelectionText: String {
        guard let comparisonBaseline, let comparisonLatest else {
            return "Choose an angle with at least two saved local photos."
        }

        let first = comparisonBaseline.capturedAt.formatted(date: .abbreviated, time: .omitted)
        let second = comparisonLatest.capturedAt.formatted(date: .abbreviated, time: .omitted)
        return "Comparing \(first) with \(second)."
    }

    var saveButtonTitle: String {
        switch saveState {
        case .saving:
            return "Saving staged photos..."
        case .saved:
            return "Saved locally"
        case .failed:
            return "Try again"
        case .idle:
            return "Save staged set"
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
        !stagedPhotos.isEmpty && saveState != .saving
    }

    var statusMessage: String? {
        switch saveState {
        case .saved(let date):
            return "Saved \(date.formatted(date: .abbreviated, time: .shortened))"
        case .failed(let message):
            return message
        case .idle, .saving:
            return nil
        }
    }

    var recentSummaryText: String {
        guard let latest = recentPhotos.first else {
            return "No saved progress photos yet."
        }

        let date = latest.capturedAt.formatted(date: .abbreviated, time: .omitted)
        return "Latest entry: \(latest.angle.displayName) on \(date)."
    }

    var recentEntriesText: String {
        if recentPhotos.isEmpty {
            return "Saved progress photos will appear here once you stage and save a local set."
        }

        return "Showing the most recent saved entries from your local history."
    }

    func stagedPhoto(for angle: ProgressPhotoAngle) -> PhotoMetadata? {
        stagedPhotos[angle]
    }

    func setComparisonAngle(_ angle: ProgressPhotoAngle) {
        comparisonAngle = angle
        updateComparisonSelection()
    }

    func setComparisonBaseline(_ id: UUID) {
        comparisonBaselineID = id
        if comparisonLatestID == id {
            comparisonLatestID = comparisonCandidates.last(where: { $0.id != id })?.id
        }
    }

    func setComparisonLatest(_ id: UUID) {
        comparisonLatestID = id
        if comparisonBaselineID == id {
            comparisonBaselineID = comparisonCandidates.first(where: { $0.id != id })?.id
        }
    }

    private func updateComparisonSelection() {
        let candidates = comparisonCandidates
        guard !candidates.isEmpty else {
            comparisonBaselineID = nil
            comparisonLatestID = nil
            return
        }

        if comparisonBaselineID == nil || !candidates.contains(where: { $0.id == comparisonBaselineID }) {
            comparisonBaselineID = candidates.first?.id
        }
        if comparisonLatestID == nil || !candidates.contains(where: { $0.id == comparisonLatestID }) || comparisonLatestID == comparisonBaselineID {
            comparisonLatestID = candidates.last(where: { $0.id != comparisonBaselineID })?.id
        }
    }

    private func angleOrder(_ angle: ProgressPhotoAngle) -> Int {
        ProgressPhotoAngle.allCases.firstIndex(of: angle) ?? 0
    }
}

@MainActor
private final class MemoryProgressPhotoRepository: ProgressPhotoRepository {
    private var photos: [ProgressPhotoMetadata] = []

    func fetchProgressPhotos(in dateInterval: DateInterval) async throws -> [ProgressPhotoMetadata] {
        photos
            .filter { dateInterval.contains($0.capturedAt) }
            .sorted { $0.capturedAt > $1.capturedAt }
    }

    func saveProgressPhoto(_ photo: ProgressPhotoMetadata) async throws {
        photos.removeAll { $0.id == photo.id }
        photos.append(photo)
    }

    func deleteProgressPhoto(id: ProgressPhotoMetadata.ID) async throws {
        photos.removeAll { $0.id == id }
    }
}

extension ProgressPhotoAngle {
    var displayName: String {
        switch self {
        case .front:
            return "Front"
        case .back:
            return "Back"
        case .left:
            return "Left"
        case .right:
            return "Right"
        }
    }

    var caption: String {
        switch self {
        case .front:
            return "Face forward"
        case .back:
            return "Turn away"
        case .left:
            return "Left profile"
        case .right:
            return "Right profile"
        }
    }
}
