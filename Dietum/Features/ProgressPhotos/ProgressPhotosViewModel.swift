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
        guard let latest = recentPhotos.first else {
            return "Capture a full set to start comparing progress over time."
        }

        guard let previousSameAngle = recentPhotos.dropFirst().first(where: { $0.angle == latest.angle }) else {
            return "Add another \(latest.angle.displayName.lowercased()) photo to compare the same pose."
        }

        let days = Calendar.current.dateComponents([.day], from: previousSameAngle.capturedAt, to: latest.capturedAt).day ?? 0
        if days <= 0 {
            return "The latest \(latest.angle.displayName.lowercased()) photo was captured on the same day as the prior one."
        }

        return "The latest \(latest.angle.displayName.lowercased()) photo is \(days) day\(days == 1 ? "" : "s") after the previous one."
    }

    var comparisonDetail: String {
        guard !recentPhotos.isEmpty else {
            return "Save a few local entries, then repeat the same angle for a simple side-by-side comparison later."
        }

        let angleCount = Set(recentPhotos.map(\.angle)).count
        return "\(angleCount) of 4 angles appear in your recent history. Keeping the pose and lighting consistent will make the comparison more useful."
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
