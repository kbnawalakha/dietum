import Foundation
import SwiftUI
import UIKit
import Vision

struct BodyFatReferenceBand: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let range: String
    let detail: String

    static let guide: [BodyFatReferenceBand] = [
        BodyFatReferenceBand(id: "lean", title: "Very lean", range: "Below 10%", detail: "More definition is often visible, but this is not a target for everyone."),
        BodyFatReferenceBand(id: "active", title: "Active range", range: "10-20%", detail: "A broad reference range for many active adults."),
        BodyFatReferenceBand(id: "general", title: "General range", range: "20-30%", detail: "A broad middle reference band; age and sex meaningfully affect interpretation."),
        BodyFatReferenceBand(id: "higher", title: "Higher range", range: "Above 30%", detail: "Consider discussing goals with a qualified health professional rather than judging from photos.")
    ]
}

struct ProgressPhotoDayGroup: Identifiable, Hashable, Sendable {
    let day: Date
    let photos: [ProgressPhotoMetadata]

    var id: Date { day }
}

@MainActor
final class ProgressPhotosViewModel: ObservableObject {
    enum BodyAnalysisState: Equatable {
        case idle
        case analyzing
        case analyzed(String)
        case failed(String)
    }

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
    @Published var bodyFatPercentageText: String = ""
    @Published var chestBodyFatText: String = ""
    @Published var armsBodyFatText: String = ""
    @Published var legsBodyFatText: String = ""
    @Published var backBodyFatText: String = ""
    @Published var visceralBodyFatText: String = ""
    @Published var selectedBodyFatReferenceID: String?
    @Published var stagedPhotos: [ProgressPhotoAngle: PhotoMetadata] = [:]
    @Published var recentPhotos: [ProgressPhotoMetadata] = []
    @Published var comparisonAngle: ProgressPhotoAngle = .front
    @Published var comparisonBaselineID: UUID?
    @Published var comparisonLatestID: UUID?
    @Published var saveState: SaveState = .idle
    @Published var loadState: LoadState = .idle
    @Published private(set) var photoSelectionError: String?
    @Published private(set) var bodyAnalysisState: BodyAnalysisState = .idle

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

    func stagePhoto(for angle: ProgressPhotoAngle, image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            saveState = .failed("The selected photo could not be prepared for local storage.")
            return
        }

        captureSequence += 1
        let storageIdentifier = "progress-photo-\(angle.rawValue)-\(String(format: "%02d", captureSequence))"
        stagedPhotos[angle] = PhotoMetadata(
            storageIdentifier: storageIdentifier,
            capturedAt: .now,
            imageData: imageData
        )
        photoSelectionError = nil
        saveState = .idle
    }

    func stagePhotoAndAnalyze(for angle: ProgressPhotoAngle, image: UIImage) async {
        stagePhoto(for: angle, image: image)
        await analyzeBodyPhotos()
    }

    func photoSelectionFailed() {
        photoSelectionError = "The selected photo could not be loaded. Please try another image."
        saveState = .failed("The selected photo could not be loaded. Please try another image.")
    }

    func saveStagedPhotos() async {
        guard hasRequiredPhotoSet else {
            saveState = .failed("Stage front, back, and either the left or right profile before saving.")
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
                    notes: noteText.isEmpty ? nil : noteText,
                    bodyFatPercentage: bodyFatPercentage,
                    bodyFatBreakdown: bodyFatBreakdown
                )
                try await progressPhotoRepository.saveProgressPhoto(metadata)
            }

            stagedPhotos.removeAll()
            notes = ""
            bodyFatPercentageText = ""
            clearBodyFatBreakdown()
            selectedBodyFatReferenceID = nil
            bodyAnalysisState = .idle
            saveState = .saved(Date())
            await loadRecentPhotos()
        } catch {
            saveState = .failed("Unable to save the staged progress photos right now.")
        }
    }

    func clearStagedPhotos() {
        stagedPhotos.removeAll()
        photoSelectionError = nil
        notes = ""
        bodyFatPercentageText = ""
        clearBodyFatBreakdown()
        selectedBodyFatReferenceID = nil
        bodyAnalysisState = .idle
        saveState = .idle
    }

    var bodyFatPercentage: Double? {
        guard let value = Double(bodyFatPercentageText.trimmingCharacters(in: .whitespacesAndNewlines)), (1...70).contains(value) else {
            return nil
        }

        return value
    }

    var bodyFatBreakdown: BodyFatEstimateBreakdown? {
        let breakdown = BodyFatEstimateBreakdown(
            chestPercentage: parsedEstimate(chestBodyFatText),
            armsPercentage: parsedEstimate(armsBodyFatText),
            legsPercentage: parsedEstimate(legsBodyFatText),
            backPercentage: parsedEstimate(backBodyFatText),
            visceralPercentage: parsedEstimate(visceralBodyFatText)
        )
        return breakdown.isEmpty ? nil : breakdown
    }

    var bodyFatEstimateText: String {
        if let bodyFatPercentage {
            let band = BodyFatReferenceBand.guide.first { band in
                switch band.id {
                case "lean": return bodyFatPercentage < 10
                case "active": return bodyFatPercentage < 20
                case "general": return bodyFatPercentage <= 30
                default: return true
                }
            }

            return "Measured estimate: \(bodyFatPercentage.formatted(.number.precision(.fractionLength(0))))% (\(band?.title ?? "reference range"))."
        }

        guard let selectedBodyFatReferenceID,
              let band = BodyFatReferenceBand.guide.first(where: { $0.id == selectedBodyFatReferenceID }) else {
            return stagedPhotos.isEmpty
                ? "Upload a photo set to choose a visual body-fat range."
                : "Choose the closest visual body-fat range below."
        }

        return "Visual estimate: \(band.title) (\(band.range))."
    }

    var bodyAnalysisText: String {
        switch bodyAnalysisState {
        case .idle:
            return stagedPhotos.isEmpty ? "Upload at least one body photo to analyze it locally." : "Analyze the staged photos to check the body framing."
        case .analyzing:
            return "Checking the staged photos for a detectable human body..."
        case .analyzed(let message), .failed(let message):
            return message
        }
    }

    var canAnalyzeBodyPhotos: Bool {
        !stagedPhotos.isEmpty && bodyAnalysisState != .analyzing
    }

    func analyzeBodyPhotos() async {
        guard !stagedPhotos.isEmpty else {
            bodyAnalysisState = .failed("Stage at least one body photo before analyzing.")
            return
        }

        bodyAnalysisState = .analyzing
        let imageData = stagedPhotos.values.compactMap(\.imageData)
        let validImageCount = imageData.reduce(into: 0) { count, data in
            if UIImage(data: data) != nil {
                count += 1
            }
        }

        guard validImageCount > 0 else {
            bodyAnalysisState = .failed("The staged photo data could not be decoded. Choose the photo again and retry.")
            return
        }

        let detectedCount = await Task.detached(priority: .userInitiated) {
            Self.detectedHumanBodyCount(in: imageData)
        }.value

        if detectedCount == 0 {
            applySuggestedBodyFatBreakdown()
            let photoWord = validImageCount == 1 ? "photo was" : "photos were"
            bodyAnalysisState = .analyzed("The \(photoWord) loaded, but pose detection was inconclusive. Review the editable visual estimates below; use a brighter, less obstructed full-body photo for stronger framing feedback.")
        } else {
            applySuggestedBodyFatBreakdown()
            let photoWord = detectedCount == 1 ? "photo" : "photos"
            bodyAnalysisState = .analyzed("Body detected in \(detectedCount) \(photoWord). Review the non-clinical regional estimates and edit them before saving.")
        }
    }

    func selectBodyFatReference(_ band: BodyFatReferenceBand) {
        selectedBodyFatReferenceID = band.id
    }

    var headline: String {
        switch loadState {
        case .loading:
            return "Loading your local progress-photo history."
        case .failed(let message):
            return message
        case .idle, .loaded:
            return "Choose front, back, and either profile side, then save the set locally."
        }
    }

    var stagedCountText: String {
        if stagedPhotos.isEmpty {
            return "No staged photos yet."
        }

        let count = stagedPhotos.count
        return "\(count) photo\(count == 1 ? "" : "s") staged. Front, back, and one profile side are required."
    }

    var stagedSummaryText: String {
        guard !stagedPhotos.isEmpty else {
            return "Choose a photo from your library or camera for any pose."
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
        hasRequiredPhotoSet && saveState != .saving
    }

    var hasRequiredPhotoSet: Bool {
        stagedPhotos[.front] != nil
            && stagedPhotos[.back] != nil
            && (stagedPhotos[.left] != nil || stagedPhotos[.right] != nil)
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

    nonisolated private static func detectedHumanBodyCount(in imageData: [Data]) -> Int {
        imageData.reduce(into: 0) { count, data in
            guard let image = UIImage(data: data), let cgImage = image.cgImage else {
                return
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                let poseRequest = VNDetectHumanBodyPoseRequest()
                try handler.perform([poseRequest])
                if !(poseRequest.results ?? []).isEmpty {
                    count += 1
                    return
                }

                let rectangleRequest = VNDetectHumanRectanglesRequest()
                try handler.perform([rectangleRequest])
                if !(rectangleRequest.results ?? []).isEmpty {
                    count += 1
                }
            } catch {
                return
            }
        }
    }

    var recentEntriesText: String {
        if recentPhotos.isEmpty {
            return "Saved progress photos will appear here once you stage and save a local set."
        }

        return "Showing the most recent saved entries from your local history."
    }

    var recentPhotoGroups: [ProgressPhotoDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: recentPhotos) { photo in
            calendar.startOfDay(for: photo.capturedAt)
        }

        return grouped
            .map { ProgressPhotoDayGroup(day: $0.key, photos: $0.value.sorted { $0.capturedAt > $1.capturedAt }) }
            .sorted { $0.day > $1.day }
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

    private func parsedEstimate(_ value: String) -> Double? {
        guard let number = Double(value.trimmingCharacters(in: .whitespacesAndNewlines)), (1...70).contains(number) else {
            return nil
        }
        return number
    }

    private func clearBodyFatBreakdown() {
        chestBodyFatText = ""
        armsBodyFatText = ""
        legsBodyFatText = ""
        backBodyFatText = ""
        visceralBodyFatText = ""
    }

    private func applySuggestedBodyFatBreakdown() {
        let baseline = bodyFatPercentage
            ?? BodyFatReferenceBand.guide.first(where: { $0.id == selectedBodyFatReferenceID }).map(Self.midpoint(of:))
            ?? 25

        chestBodyFatText = formattedEstimate(baseline)
        armsBodyFatText = formattedEstimate(baseline - 1)
        legsBodyFatText = formattedEstimate(baseline + 2)
        backBodyFatText = formattedEstimate(baseline + 1)
        visceralBodyFatText = formattedEstimate(baseline * 0.9)
    }

    private func formattedEstimate(_ value: Double) -> String {
        String(format: "%.1f", min(max(value, 1), 70))
    }

    private static func midpoint(of band: BodyFatReferenceBand) -> Double {
        switch band.id {
        case "lean": return 8
        case "active": return 15
        case "general": return 25
        default: return 35
        }
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
