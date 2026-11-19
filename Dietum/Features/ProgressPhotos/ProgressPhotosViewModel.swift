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

struct ProgressPhotoChange: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
}

struct ProgressPhotoVisualComparison: Hashable, Sendable {
    let fatDescription: String
    let muscleDescription: String
    let shapeDescription: String
    let methodDescription: String
}

private struct ProgressPhotoBodyMetrics {
    let bodyWidthRatio: Double
    let shoulderWidthRatio: Double
    let hipWidthRatio: Double
    let chestWidthRatio: Double
    let waistSilhouetteRatio: Double
    let hipSilhouetteRatio: Double
    let thighWidthRatio: Double
    let calfWidthRatio: Double
    let definitionScore: Double
    let chestDefinitionScore: Double
    let armDefinitionScore: Double
    let legDefinitionScore: Double
}

private enum ProgressPhotoComparisonAnalyzer {
    static func compare(earlier: PhotoMetadata, later: PhotoMetadata) -> ProgressPhotoVisualComparison? {
        guard let earlierData = earlier.imageData,
              let laterData = later.imageData,
              let earlierImage = UIImage(data: earlierData)?.cgImage,
              let laterImage = UIImage(data: laterData)?.cgImage,
              let earlierMetrics = metrics(for: earlierImage),
              let laterMetrics = metrics(for: laterImage) else {
            return nil
        }

        let bodyWidthChange = signedChange(from: earlierMetrics.bodyWidthRatio, to: laterMetrics.bodyWidthRatio)
        let hipWidthChange = signedChange(from: earlierMetrics.hipWidthRatio, to: laterMetrics.hipWidthRatio)
        let waistChange = signedChange(from: earlierMetrics.waistSilhouetteRatio, to: laterMetrics.waistSilhouetteRatio)
        let hipSilhouetteChange = signedChange(from: earlierMetrics.hipSilhouetteRatio, to: laterMetrics.hipSilhouetteRatio)
        let shoulderChange = signedChange(from: earlierMetrics.shoulderWidthRatio, to: laterMetrics.shoulderWidthRatio)
        let definitionChange = signedChange(from: earlierMetrics.definitionScore, to: laterMetrics.definitionScore)
        let chestDefinitionChange = signedChange(from: earlierMetrics.chestDefinitionScore, to: laterMetrics.chestDefinitionScore)
        let armDefinitionChange = signedChange(from: earlierMetrics.armDefinitionScore, to: laterMetrics.armDefinitionScore)
        let legDefinitionChange = signedChange(from: earlierMetrics.legDefinitionScore, to: laterMetrics.legDefinitionScore)

        return ProgressPhotoVisualComparison(
            fatDescription: fullnessDescription(
                bodyWidthChange: bodyWidthChange,
                hipWidthChange: hipWidthChange,
                waistChange: waistChange,
                hipSilhouetteChange: hipSilhouetteChange
            ),
            muscleDescription: definitionDescription(
                definitionChange: definitionChange,
                shoulderChange: shoulderChange,
                chestDefinitionChange: chestDefinitionChange,
                armDefinitionChange: armDefinitionChange,
                legDefinitionChange: legDefinitionChange
            ),
            shapeDescription: shapeDescription(
                bodyWidthChange: bodyWidthChange,
                hipWidthChange: hipWidthChange,
                waistChange: waistChange,
                hipSilhouetteChange: hipSilhouetteChange,
                shoulderChange: shoulderChange
            ),
            methodDescription: "Compared Vision pose landmarks, a normalized person silhouette profile at the waist and hips, and regional surface-definition signals. This is a 2D visual comparison, not the paper's DXA-calibrated model or a clinical body-composition measurement."
        )
    }

    private static func metrics(for image: CGImage) -> ProgressPhotoBodyMetrics? {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        let poseRequest = VNDetectHumanBodyPoseRequest()

        try? handler.perform([poseRequest])
        var points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
        if let observation = poseRequest.results?.first,
           let recognizedPoints = try? observation.recognizedPoints(.all) {
            points = recognizedPoints
        }

        func point(_ joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            guard let recognized = points[joint], recognized.confidence >= 0.2 else {
                return nil
            }
            return recognized.location
        }

        let silhouette = silhouetteMetrics(for: image)
        let posePoints = points.values
            .filter { $0.confidence >= 0.2 }
            .map(\.location)
        let poseBounds = normalizedBounds(for: posePoints)
        let bodyBounds = silhouette?.bodyBounds ?? poseBounds
        guard let bodyBounds, bodyBounds.height > 0 else {
            return nil
        }

        let bodyHeight = bodyBounds.height
        let poseBodyWidthRatio = bodyBounds.width / bodyHeight
        let bodyWidthRatio = silhouette?.bodyWidthRatio ?? poseBodyWidthRatio
        let shoulderWidthRatio: Double
        if let leftShoulder = point(.leftShoulder), let rightShoulder = point(.rightShoulder) {
            shoulderWidthRatio = distance(leftShoulder, rightShoulder) / bodyHeight
        } else {
            shoulderWidthRatio = bodyWidthRatio
        }
        let hipWidthRatio: Double
        if let leftHip = point(.leftHip), let rightHip = point(.rightHip) {
            hipWidthRatio = distance(leftHip, rightHip) / bodyHeight
        } else {
            hipWidthRatio = silhouette?.hipWidthRatio ?? bodyWidthRatio
        }

        return ProgressPhotoBodyMetrics(
            bodyWidthRatio: bodyWidthRatio,
            shoulderWidthRatio: shoulderWidthRatio,
            hipWidthRatio: hipWidthRatio,
            chestWidthRatio: silhouette?.chestWidthRatio ?? bodyWidthRatio,
            waistSilhouetteRatio: silhouette?.waistWidthRatio ?? bodyWidthRatio,
            hipSilhouetteRatio: silhouette?.hipWidthRatio ?? hipWidthRatio,
            thighWidthRatio: silhouette?.thighWidthRatio ?? bodyWidthRatio * 0.55,
            calfWidthRatio: silhouette?.calfWidthRatio ?? bodyWidthRatio * 0.35,
            definitionScore: surfaceDefinitionScore(image, bodyBounds: bodyBounds),
            chestDefinitionScore: regionDefinitionScore(image, bodyBounds: bodyBounds, x: 0.25...0.75, y: 0.35...0.65),
            armDefinitionScore: regionDefinitionScore(image, bodyBounds: bodyBounds, x: 0.05...0.95, y: 0.25...0.65),
            legDefinitionScore: regionDefinitionScore(image, bodyBounds: bodyBounds, x: 0.20...0.80, y: 0.00...0.40)
        )
    }

    private static func normalizedBounds(for points: [CGPoint]) -> CGRect? {
        guard let minX = points.map(\.x).min(),
              let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(),
              let maxY = points.map(\.y).max(),
              maxX > minX,
              maxY > minY else {
            return nil
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private static func silhouetteMetrics(for image: CGImage) -> (
        bodyWidthRatio: Double,
        chestWidthRatio: Double,
        waistWidthRatio: Double,
        hipWidthRatio: Double,
        thighWidthRatio: Double,
        calfWidthRatio: Double,
        bodyBounds: CGRect
    )? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        do {
            try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        } catch {
            return nil
        }

        guard let mask = request.results?.first?.pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(mask) else {
            return nil
        }

        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        let pixels = baseAddress.assumingMemoryBound(to: UInt8.self)
        let threshold: UInt8 = 128

        var firstRow: Int?
        var lastRow: Int?
        var rows: [(minX: Int, maxX: Int)] = []
        rows.reserveCapacity(height)

        for y in 0..<height {
            var minX = width
            var maxX = -1
            let row = pixels.advanced(by: y * bytesPerRow)
            for x in 0..<width where row[x] >= threshold {
                minX = min(minX, x)
                maxX = max(maxX, x)
            }
            rows.append((minX, maxX))
            if maxX >= minX {
                firstRow = firstRow ?? y
                lastRow = y
            }
        }

        guard let firstRow, let lastRow, lastRow > firstRow else {
            return nil
        }

        let bodyHeight = Double(lastRow - firstRow + 1)

        func widthRatio(at fraction: Double) -> Double? {
            let rowIndex = min(lastRow, max(firstRow, firstRow + Int(bodyHeight * fraction)))
            let row = rows[rowIndex]
            guard row.maxX >= row.minX else {
                return nil
            }
            return Double(row.maxX - row.minX + 1) / bodyHeight
        }

        guard let chestWidthRatio = widthRatio(at: 0.36),
              let waistWidthRatio = widthRatio(at: 0.52),
              let hipWidthRatio = widthRatio(at: 0.65),
              let thighWidthRatio = widthRatio(at: 0.75),
              let calfWidthRatio = widthRatio(at: 0.86) else {
            return nil
        }

        let widestRow = rows[firstRow...lastRow].max { lhs, rhs in
            (lhs.maxX - lhs.minX) < (rhs.maxX - rhs.minX)
        }
        guard let widestRow, widestRow.maxX >= widestRow.minX else {
            return nil
        }

        let bodyBounds = CGRect(
            x: Double(widestRow.minX) / Double(width),
            y: 1 - Double(lastRow + 1) / Double(height),
            width: Double(widestRow.maxX - widestRow.minX + 1) / Double(width),
            height: bodyHeight / Double(height)
        )
        return (
            bodyWidthRatio: Double(widestRow.maxX - widestRow.minX + 1) / bodyHeight,
            chestWidthRatio: chestWidthRatio,
            waistWidthRatio: waistWidthRatio,
            hipWidthRatio: hipWidthRatio,
            thighWidthRatio: thighWidthRatio,
            calfWidthRatio: calfWidthRatio,
            bodyBounds: bodyBounds
        )
    }

    static func estimatedMeasurements(for image: CGImage, referenceHeightCentimeters: Double = 170) -> BodyMeasurementEstimate? {
        guard let bodyMetrics = metrics(for: image), referenceHeightCentimeters > 0 else {
            return nil
        }

        // A front-facing silhouette gives width/height ratios, not absolute size.
        // Convert those ratios using a generic height reference and label the result as estimated.
        func circumference(from widthRatio: Double, ellipseFactor: Double = 0.85) -> Double {
            max(1, widthRatio * referenceHeightCentimeters * .pi * ellipseFactor)
        }

        let armWidthRatio = min(bodyMetrics.shoulderWidthRatio * 0.18, bodyMetrics.bodyWidthRatio * 0.16)
        let thighWidthRatio = bodyMetrics.thighWidthRatio * 0.42
        let calfWidthRatio = bodyMetrics.calfWidthRatio * 0.55

        return BodyMeasurementEstimate(
            chestCentimeters: circumference(from: bodyMetrics.chestWidthRatio),
            waistCentimeters: circumference(from: bodyMetrics.waistSilhouetteRatio),
            hipCentimeters: circumference(from: bodyMetrics.hipSilhouetteRatio),
            upperArmCentimeters: circumference(from: armWidthRatio, ellipseFactor: 0.75),
            thighCentimeters: circumference(from: thighWidthRatio, ellipseFactor: 0.75),
            calfCentimeters: circumference(from: calfWidthRatio, ellipseFactor: 0.75)
        )
    }

    private static func regionDefinitionScore(
        _ image: CGImage,
        bodyBounds: CGRect,
        x: ClosedRange<Double>,
        y: ClosedRange<Double>
    ) -> Double {
        let region = CGRect(
            x: bodyBounds.minX + bodyBounds.width * x.lowerBound,
            y: bodyBounds.minY + bodyBounds.height * y.lowerBound,
            width: bodyBounds.width * (x.upperBound - x.lowerBound),
            height: bodyBounds.height * (y.upperBound - y.lowerBound)
        )
        return surfaceDefinitionScore(image, bodyBounds: region)
    }

    private static func surfaceDefinitionScore(_ image: CGImage, bodyBounds: CGRect) -> Double {
        let width = 64
        let height = 64
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let xStart = max(0, Int(bodyBounds.minX * Double(width)))
        let xEnd = min(width - 1, Int(bodyBounds.maxX * Double(width)))
        let yStart = max(0, Int(bodyBounds.minY * Double(height)))
        let yEnd = min(height - 1, Int(bodyBounds.maxY * Double(height)))
        guard xEnd > xStart, yEnd > yStart else {
            return 0
        }

        func luminance(_ x: Int, _ y: Int) -> Double {
            let offset = ((y * width) + x) * 4
            return (0.2126 * Double(pixels[offset]) + 0.7152 * Double(pixels[offset + 1]) + 0.0722 * Double(pixels[offset + 2])) / 255
        }

        var total = 0.0
        var samples = 0
        for y in yStart..<yEnd {
            for x in xStart..<xEnd {
                total += abs(luminance(x, y) - luminance(x + 1, y))
                total += abs(luminance(x, y) - luminance(x, y + 1))
                samples += 2
            }
        }
        return samples == 0 ? 0 : total / Double(samples)
    }

    private static func distance(_ first: CGPoint, _ second: CGPoint) -> Double {
        hypot(first.x - second.x, first.y - second.y)
    }

    private static func signedChange(from earlier: Double, to later: Double) -> Double {
        guard earlier > 0 else { return 0 }
        return (later - earlier) / earlier
    }

    private static func fullnessDescription(
        bodyWidthChange: Double,
        hipWidthChange: Double,
        waistChange: Double,
        hipSilhouetteChange: Double
    ) -> String {
        let change = (bodyWidthChange + hipWidthChange + waistChange + hipSilhouetteChange) / 4
        if change < -0.04 { return "The later photo looks less full through the torso and hips than the earlier photo." }
        if change > 0.04 { return "The later photo looks fuller through the torso and hips than the earlier photo." }
        return "The torso and hip fullness looks the same in both photos."
    }

    private static func definitionDescription(
        definitionChange: Double,
        shoulderChange: Double,
        chestDefinitionChange: Double,
        armDefinitionChange: Double,
        legDefinitionChange: Double
    ) -> String {
        let shoulderDirection = shoulderChange >= 0 ? "wider" : "narrower"
        let regionalSignals = [
            regionalDefinitionText("chest", change: chestDefinitionChange),
            regionalDefinitionText("arms", change: armDefinitionChange),
            regionalDefinitionText("legs", change: legDefinitionChange)
        ].compactMap { $0 }
        let regionalSummary = regionalSignals.isEmpty
            ? "The chest, arms, and legs look the same in both photos."
            : regionalSignals.joined(separator: " ")

        if definitionChange > 0.12 {
            return "The later photo shows more visible muscle definition overall, and the shoulders look \(shoulderDirection). \(regionalSummary)"
        }
        if definitionChange < -0.12 {
            return "The later photo shows less visible muscle definition overall. \(regionalSummary)"
        }
        return "The overall muscle definition looks the same in both photos. \(regionalSummary)"
    }

    private static func regionalDefinitionText(_ region: String, change: Double) -> String? {
        if change > 0.12 {
            return "The later photo shows more visible \(region) definition than the earlier photo."
        }
        if change < -0.12 {
            return "The later photo shows less visible \(region) definition than the earlier photo."
        }
        return nil
    }

    private static func shapeDescription(
        bodyWidthChange: Double,
        hipWidthChange: Double,
        waistChange: Double,
        hipSilhouetteChange: Double,
        shoulderChange: Double
    ) -> String {
        let trunk = shapeChangeText("torso", change: bodyWidthChange)
        let waist = shapeChangeText("waist", change: waistChange)
        let hips = shapeChangeText("hips", change: hipWidthChange)
        let shoulders = shapeChangeText("shoulders", change: shoulderChange)
        let silhouetteHips = shapeChangeText("hip contour", change: hipSilhouetteChange)
        if [bodyWidthChange, hipWidthChange, waistChange, hipSilhouetteChange, shoulderChange].allSatisfy({ abs($0) <= 0.04 }) {
            return "The torso, waist, hips, and shoulders look the same in both photos."
        }
        return "\(trunk) \(waist) \(hips) \(silhouetteHips) \(shoulders)"
    }

    private static func shapeChangeText(_ region: String, change: Double) -> String {
        if change < -0.04 {
            return "The later photo looks narrower through the \(region) than the earlier photo."
        }
        if change > 0.04 {
            return "The later photo looks broader through the \(region) than the earlier photo."
        }
        return "The \(region) look the same in both photos."
    }
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
    @Published private(set) var measurementEstimate: BodyMeasurementEstimate?
    @Published var selectedBodyFatReferenceID: String?
    @Published var stagedPhotos: [ProgressPhotoAngle: PhotoMetadata] = [:]
    @Published var photoDate: Date = .now
    @Published var recentPhotos: [ProgressPhotoMetadata] = []
    @Published var comparisonAngle: ProgressPhotoAngle = .front
    @Published var comparisonBaselineID: UUID?
    @Published var comparisonLatestID: UUID?
    @Published private(set) var comparisonVisualAnalysis: ProgressPhotoVisualComparison?
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
            capturedAt: photoDate,
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
                    bodyFatBreakdown: bodyFatBreakdown,
                    bodyMeasurementEstimate: measurementEstimate
                )
                try await progressPhotoRepository.saveProgressPhoto(metadata)
            }

            stagedPhotos.removeAll()
            notes = ""
            bodyFatPercentageText = ""
            clearBodyFatBreakdown()
            measurementEstimate = nil
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
        photoDate = .now
        photoSelectionError = nil
        notes = ""
        bodyFatPercentageText = ""
        clearBodyFatBreakdown()
        measurementEstimate = nil
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
            return stagedPhotos.isEmpty ? "Upload at least one body photo to analyze its composition." : "Analyze the staged photos to calculate regional composition estimates."
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

        let analysis = await Task.detached(priority: .userInitiated) {
            let detectedCount = Self.detectedHumanBodyCount(in: imageData)
            let measurements = imageData
                .compactMap { UIImage(data: $0)?.cgImage }
                .compactMap { ProgressPhotoComparisonAnalyzer.estimatedMeasurements(for: $0) }
            return (detectedCount, Self.averageMeasurements(measurements))
        }.value
        measurementEstimate = analysis.1

        if analysis.0 == 0 {
            applySuggestedBodyFatBreakdown()
            let photoWord = validImageCount == 1 ? "photo was" : "photos were"
            bodyAnalysisState = .analyzed("The \(photoWord) loaded, but pose detection was inconclusive. Review the automatic regional composition and measurement estimates below before saving.")
        } else {
            applySuggestedBodyFatBreakdown()
            let photoWord = analysis.0 == 1 ? "photo" : "photos"
            bodyAnalysisState = .analyzed("Body detected in \(analysis.0) \(photoWord). Review the automatic non-clinical regional and measurement estimates before saving.")
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

        return "Photo composition comparison is available for the selected dates."
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

    var comparisonChanges: [ProgressPhotoChange] {
        guard let comparisonBaseline, let comparisonLatest else {
            return []
        }

        var changes: [ProgressPhotoChange] = []
        if let change = makeChange(
            id: "overall",
            title: "Overall",
            earlier: comparisonBaseline.bodyFatPercentage,
            later: comparisonLatest.bodyFatPercentage
        ) {
            changes.append(change)
        }

        let earlierBreakdown = comparisonBaseline.bodyFatBreakdown
        let laterBreakdown = comparisonLatest.bodyFatBreakdown
        let regions: [(String, String, Double?, Double?)] = [
            ("chest", "Chest", earlierBreakdown?.chestPercentage, laterBreakdown?.chestPercentage),
            ("arms", "Arms", earlierBreakdown?.armsPercentage, laterBreakdown?.armsPercentage),
            ("legs", "Legs", earlierBreakdown?.legsPercentage, laterBreakdown?.legsPercentage),
            ("back", "Back", earlierBreakdown?.backPercentage, laterBreakdown?.backPercentage),
            ("visceral", "Visceral", earlierBreakdown?.visceralPercentage, laterBreakdown?.visceralPercentage)
        ]

        for (id, title, earlier, later) in regions {
            if let change = makeChange(id: id, title: title, earlier: earlier, later: later) {
                changes.append(change)
            }
        }

        if changes.isEmpty {
            return [ProgressPhotoChange(
                id: "unavailable",
                title: "Analysis unavailable",
                detail: "The two photos can still be compared visually, but both need the same saved estimate before numeric changes can be calculated."
            )]
        }

        return changes
    }

    var comparisonCompositionSignals: [ProgressPhotoChange] {
        guard comparisonBaseline != nil, comparisonLatest != nil else {
            return []
        }

        let fatDetail: String
        if let overall = comparisonChanges.first(where: { $0.id == "overall" }) {
            fatDetail = overall.detail
        } else {
            fatDetail = "Save an overall body-fat estimate for both photos to compare fat change."
        }

        let visualFatDetail = comparisonVisualAnalysis.map { $0.fatDescription } ?? ""
        let visualMuscleDetail = comparisonVisualAnalysis?.muscleDescription
            ?? "Muscle mass is not measurable from a 2D photo alone, and no image-based definition signal is available because both photos need readable local image data."
        let visualShapeDetail = comparisonVisualAnalysis?.shapeDescription
            ?? "Use the side-by-side images to compare waist, shoulders, limbs, and posture; no image-based shape signal is available yet."

        return [
            ProgressPhotoChange(
                id: "fat-signal",
                title: "Fat change",
                detail: visualFatDetail.isEmpty
                    ? fatDetail
                    : visualFatDetail
            ),
            ProgressPhotoChange(
                id: "muscle-signal",
                title: "Muscle composition",
                detail: visualMuscleDetail
            ),
            ProgressPhotoChange(
                id: "shape-signal",
                title: "Shape change",
                detail: visualShapeDetail
            )
        ]
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

        return "Each date contains one complete local profile set and its editable body analysis."
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

    func deletePhotoDay(_ day: Date) async {
        let calendar = Calendar.current
        let photos = recentPhotos.filter { calendar.isDate($0.capturedAt, inSameDayAs: day) }
        guard !photos.isEmpty else {
            return
        }

        do {
            for photo in photos {
                try await progressPhotoRepository.deleteProgressPhoto(id: photo.id)
            }

            recentPhotos.removeAll { photo in
                calendar.isDate(photo.capturedAt, inSameDayAs: day)
            }
            updateComparisonSelection()
        } catch {
            saveState = .failed("Unable to delete that day's progress photos right now.")
        }
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
        updateComparisonVisualAnalysis()
    }

    func setComparisonLatest(_ id: UUID) {
        comparisonLatestID = id
        if comparisonBaselineID == id {
            comparisonBaselineID = comparisonCandidates.first(where: { $0.id != id })?.id
        }
        updateComparisonVisualAnalysis()
    }

    private func updateComparisonSelection() {
        let candidates = comparisonCandidates
        guard !candidates.isEmpty else {
            comparisonBaselineID = nil
            comparisonLatestID = nil
            comparisonVisualAnalysis = nil
            return
        }

        if comparisonBaselineID == nil || !candidates.contains(where: { $0.id == comparisonBaselineID }) {
            comparisonBaselineID = candidates.first?.id
        }
        if comparisonLatestID == nil || !candidates.contains(where: { $0.id == comparisonLatestID }) || comparisonLatestID == comparisonBaselineID {
            comparisonLatestID = candidates.last(where: { $0.id != comparisonBaselineID })?.id
        }
        updateComparisonVisualAnalysis()
    }

    private func updateComparisonVisualAnalysis() {
        guard let comparisonBaseline, let comparisonLatest else {
            comparisonVisualAnalysis = nil
            return
        }

        comparisonVisualAnalysis = ProgressPhotoComparisonAnalyzer.compare(
            earlier: comparisonBaseline.photo,
            later: comparisonLatest.photo
        )
    }

    private func angleOrder(_ angle: ProgressPhotoAngle) -> Int {
        ProgressPhotoAngle.allCases.firstIndex(of: angle) ?? 0
    }

    private func makeChange(
        id: String,
        title: String,
        earlier: Double?,
        later: Double?
    ) -> ProgressPhotoChange? {
        guard let earlier, let later else {
            return nil
        }

        let difference = later - earlier
        let direction: String
        if abs(difference) < 0.05 {
            direction = "unchanged"
        } else if difference < 0 {
            direction = "down"
        } else {
            direction = "up"
        }

        let earlierText = earlier.formatted(.number.precision(.fractionLength(1)))
        let laterText = later.formatted(.number.precision(.fractionLength(1)))
        let differenceText = abs(difference).formatted(.number.precision(.fractionLength(1)))
        let detail = direction == "unchanged"
            ? "No meaningful change: \(earlierText)% to \(laterText)%"
            : "\(direction.capitalized) by \(differenceText) percentage points: \(earlierText)% to \(laterText)%"

        return ProgressPhotoChange(id: id, title: title, detail: detail)
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

    private static func averageMeasurements(_ values: [BodyMeasurementEstimate]) -> BodyMeasurementEstimate? {
        guard !values.isEmpty else { return nil }

        func average(_ component: (BodyMeasurementEstimate) -> Double?) -> Double? {
            let numbers = values.compactMap(component)
            guard !numbers.isEmpty else { return nil }
            return numbers.reduce(0, +) / Double(numbers.count)
        }

        return BodyMeasurementEstimate(
            chestCentimeters: average(\.chestCentimeters),
            waistCentimeters: average(\.waistCentimeters),
            hipCentimeters: average(\.hipCentimeters),
            upperArmCentimeters: average(\.upperArmCentimeters),
            thighCentimeters: average(\.thighCentimeters),
            calfCentimeters: average(\.calfCentimeters)
        )
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
