import Foundation
import AVFoundation
import CoreVideo

protocol VideoRhythmAnalyzing: Sendable {
    func analyze(_ url: URL) async throws -> RhythmTimeline
}

enum RhythmAnalysisError: LocalizedError {
    case unsupported, tooLarge, tooLong, unreadable, noCues, download
    var errorDescription: String? {
        switch self {
        case .unsupported: return "Analysis needs a direct MP4, M4V or MOV file. Website and HLS playback can use the manual metronome."
        case .tooLarge: return "This video is too large to analyze. Choose a file under 150 MB."
        case .tooLong: return "Choose a video up to 10 minutes long for rhythm analysis."
        case .unreadable: return "This video's tracks can’t be analyzed. Try another unprotected video."
        case .noCues: return "No clear audio or movement peaks found. Try another video or use manual tempo."
        case .download: return "The video couldn’t be downloaded for analysis. Check your connection and link, then retry."
        }
    }
}

private final class DownloadLimit: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    static let bytes: Int64 = 150 * 1024 * 1024
    private let lock = NSLock()
    private var continuation: CheckedContinuation<(URL, URLResponse), Error>?
    private var result: Result<(URL, URLResponse), Error>?
    private var exceeded = false
    let mediaExtension: String

    init(mediaExtension: String) { self.mediaExtension = mediaExtension }

    func install(_ continuation: CheckedContinuation<(URL, URLResponse), Error>) {
        lock.lock()
        if let result { lock.unlock(); continuation.resume(with: result) }
        else { self.continuation = continuation; lock.unlock() }
    }

    private func finish(_ result: Result<(URL, URLResponse), Error>) {
        lock.lock()
        guard self.result == nil else { lock.unlock(); return }
        self.result = result
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > Self.bytes || totalBytesExpectedToWrite > Self.bytes {
            lock.lock(); exceeded = true; lock.unlock()
            downloadTask.cancel()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let response = downloadTask.response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode) else { throw RhythmAnalysisError.download }
            let size = try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= Self.bytes else { throw RhythmAnalysisError.tooLarge }
            try FileManager.default.createDirectory(at: VideoRhythmAnalyzer.temporaryDirectory, withIntermediateDirectories: true)
            let media = VideoRhythmAnalyzer.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(mediaExtension)
            // The original URL is never used as a filename or persisted as history.
            try FileManager.default.moveItem(at: location, to: media)
            finish(.success((media, response)))
        } catch { finish(.failure(error)) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        lock.lock(); let tooLarge = exceeded; lock.unlock()
        finish(.failure(tooLarge ? RhythmAnalysisError.tooLarge : error))
    }
}

actor VideoRhythmAnalyzer: VideoRhythmAnalyzing {
    static var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("CounterAnalysis", isDirectory: true)
    }

    // Called once at app launch, before any analysis starts, for interrupted-session cleanup.
    static func discardAbandonedMedia() {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }
    func analyze(_ url: URL) async throws -> RhythmTimeline {
        guard ["mp4", "mov", "m4v"].contains(url.pathExtension.lowercased()) else { throw RhythmAnalysisError.unsupported }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 180
        let delegate = DownloadLimit(mediaExtension: url.pathExtension.lowercased())
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let download = session.downloadTask(with: URLRequest(url: url))
        let media: URL
        do {
            (media, _) = try await withTaskCancellationHandler {
                try Task.checkCancellation()
                return try await withCheckedThrowingContinuation { continuation in
                    delegate.install(continuation)
                    download.resume()
                }
            } onCancel: { download.cancel() }
        } catch {
            try Task.checkCancellation()
            if let typed = error as? RhythmAnalysisError { throw typed }
            throw RhythmAnalysisError.download
        }
        defer { try? FileManager.default.removeItem(at: media) }
        try Task.checkCancellation()
        return try await analyzeAsset(AVURLAsset(url: media))
    }

    func analyzeAsset(_ asset: AVAsset) async throws -> RhythmTimeline {
        try Task.checkCancellation()
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else { throw RhythmAnalysisError.unreadable }
        guard duration <= 600 else { throw RhythmAnalysisError.tooLong }
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audio = try audioTracks.first.map { try audioSamples(asset, track: $0) } ?? []
        try Task.checkCancellation()
        let motion = try videoTracks.first.map { try motionSamples(asset, track: $0) } ?? []
        let timeline = RhythmTimeline(
            audio: RhythmTimeline.peaks(audio, floor: 0.015, minimumGap: 0.25),
            motion: RhythmTimeline.peaks(motion, floor: 0.012, minimumGap: 0.3), duration: duration)
        guard !timeline.audio.isEmpty || !timeline.motion.isEmpty else { throw RhythmAnalysisError.noCues }
        return timeline
    }

    private func reader(_ asset: AVAsset, track: AVAssetTrack, settings: [String: Any]) throws -> (AVAssetReader, AVAssetReaderTrackOutput) {
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw RhythmAnalysisError.unreadable }
        reader.add(output)
        guard reader.startReading() else { throw RhythmAnalysisError.unreadable }
        return (reader, output)
    }

    private func audioSamples(_ asset: AVAsset, track: AVAssetTrack) throws -> [RhythmSample] {
        let (reader, output) = try reader(asset, track: track, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 8000,
            AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true, AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsBigEndianKey: false])
        defer { reader.cancelReading() }
        var result: [RhythmSample] = []
        var sum = 0.0
        var count = 0
        while let buffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            guard let block = CMSampleBufferGetDataBuffer(buffer) else { continue }
            let length = CMBlockBufferGetDataLength(block)
            guard length > 0, length % MemoryLayout<Float>.size == 0 else { throw RhythmAnalysisError.unreadable }
            var values = [Float](repeating: 0, count: length / MemoryLayout<Float>.size)
            let status = values.withUnsafeMutableBytes { bytes in
                CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: bytes.baseAddress!)
            }
            guard status == kCMBlockBufferNoErr else { throw RhythmAnalysisError.unreadable }
            let start = CMSampleBufferGetPresentationTimeStamp(buffer).seconds
            for (index, value) in values.enumerated() {
                sum += Double(value * value)
                count += 1
                if count == 160 {
                    result.append(RhythmSample(time: start + Double(index) / 8000, strength: sqrt(sum / 160)))
                    count = 0; sum = 0
                }
            }
        }
        guard reader.status == .completed else { throw RhythmAnalysisError.unreadable }
        return result
    }

    private func motionSamples(_ asset: AVAsset, track: AVAssetTrack) throws -> [RhythmSample] {
        let (reader, output) = try reader(asset, track: track, settings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        defer { reader.cancelReading() }
        var previous: [Double]?
        var lastTime = -1.0
        var result: [RhythmSample] = []
        while let buffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            let time = CMSampleBufferGetPresentationTimeStamp(buffer).seconds
            guard time - lastTime >= 1.0 / 12,
                  let image = CMSampleBufferGetImageBuffer(buffer) else { continue }
            lastTime = time
            CVPixelBufferLockBaseAddress(image, .readOnly)
            let grid: [Double] = {
                guard let base = CVPixelBufferGetBaseAddress(image) else { return [] }
                let pixels = base.assumingMemoryBound(to: UInt8.self)
                let width = CVPixelBufferGetWidth(image)
                let height = CVPixelBufferGetHeight(image)
                let stride = CVPixelBufferGetBytesPerRow(image)
                return (0..<256).map { index in
                    let x = (index % 16 * 2 + 1) * width / 32
                    let y = (index / 16 * 2 + 1) * height / 32
                    let p = y * stride + x * 4
                    return (Double(pixels[p]) + Double(pixels[p + 1]) + Double(pixels[p + 2])) / 765
                }
            }()
            CVPixelBufferUnlockBaseAddress(image, .readOnly)
            if let previous, previous.count == grid.count, !grid.isEmpty {
                let difference = zip(previous, grid).reduce(0.0) { $0 + abs($1.0 - $1.1) } / Double(grid.count)
                // Large full-frame cuts are not useful movement cues.
                result.append(RhythmSample(time: time, strength: difference > 0.45 ? 0 : difference))
            }
            previous = grid
        }
        guard reader.status == .completed else { throw RhythmAnalysisError.unreadable }
        return result
    }
}
