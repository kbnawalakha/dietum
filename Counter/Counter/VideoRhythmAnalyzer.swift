import AVFoundation
import CoreVideo
import MediaToolbox

@MainActor
protocol VideoRhythmAnalyzing: AnyObject {
    func attach(to item: AVPlayerItem)
    func sample(at time: CMTime) -> LiveRhythmSample?
    func resetSamples()
    func detach()
}

/// Reads only the frames already decoded for playback. No requests, readers, or media files.
@MainActor
final class VideoRhythmAnalyzer: VideoRhythmAnalyzing {
    private var item: AVPlayerItem?
    private var output: AVPlayerItemVideoOutput?
    private var previous: [Double]?
    private var audioWork: Task<Void, Never>?
    private var audio: StreamingAudioEnergy?
    private var lastTime = -Double.infinity

    static func removeLegacyDownloads() {
        // Remove media left by the superseded downloadable-analysis version; never creates files.
        let oldDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("CounterAnalysis", isDirectory: true)
        try? FileManager.default.removeItem(at: oldDirectory)
    }

    func attach(to item: AVPlayerItem) {
        detach()
        self.item = item
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA])
        item.add(output)
        self.output = output
        // Audio is optional: some stream formats and protected media do not expose a tap.
        audioWork = Task { [weak self, weak item] in
            guard let item else { return }
            guard let tracks = try? await item.asset.loadTracks(withMediaType: .audio),
                  !Task.isCancelled, self?.item === item, let track = tracks.first else { return }
            let audio = StreamingAudioEnergy()
            if let parameters = audio.parameters(for: track) {
                let mix = AVMutableAudioMix()
                mix.inputParameters = [parameters]
                item.audioMix = mix
                self?.audio = audio
            }
        }
    }

    func sample(at time: CMTime) -> LiveRhythmSample? {
        let seconds = time.seconds
        guard seconds.isFinite, seconds - lastTime >= 1.0 / 12,
              let output, output.hasNewPixelBuffer(forItemTime: time),
              let image = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) else { return nil }
        lastTime = seconds
        return analyze(image, at: seconds)
    }

    func analyze(_ image: CVPixelBuffer, at seconds: Double) -> LiveRhythmSample {
        let grid = Self.grid(image)
        defer { previous = grid }
        guard let previous, previous.count == grid.count, !grid.isEmpty else {
            return LiveRhythmSample(time: seconds, movement: 0, audio: audio?.energy(at: seconds))
        }
        let difference = zip(previous, grid).reduce(0.0) { $0 + abs($1.0 - $1.1) } / Double(grid.count)
        return LiveRhythmSample(time: seconds, movement: difference > 0.45 ? 0 : difference,
                                audio: audio?.energy(at: seconds))
    }

    static func grid(_ image: CVPixelBuffer) -> [Double] {
        CVPixelBufferLockBaseAddress(image, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(image, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(image) else { return [] }
        let pixels = base.assumingMemoryBound(to: UInt8.self)
        let width = CVPixelBufferGetWidth(image), height = CVPixelBufferGetHeight(image)
        let stride = CVPixelBufferGetBytesPerRow(image)
        return (0..<256).map { index in
            let x = (index % 16 * 2 + 1) * width / 32
            let y = (index / 16 * 2 + 1) * height / 32
            let offset = y * stride + x * 4
            return (Double(pixels[offset]) + Double(pixels[offset + 1]) + Double(pixels[offset + 2])) / 765
        }
    }

    func resetSamples() { previous = nil; lastTime = -.infinity; audio?.clear() }

    func detach() {
        audioWork?.cancel(); audioWork = nil
        if let output { item?.remove(output) }
        if audio != nil { item?.audioMix = nil }
        output = nil; item = nil; audio = nil
        resetSamples()
    }
}

/// Keeps a single RMS reading in RAM. The tap passes source audio through unchanged.
private final class StreamingAudioEnergy: @unchecked Sendable {
    private let lock = NSLock()
    private var latest: (time: Double, energy: Double)?
    private var format = AudioStreamBasicDescription()

    func clear() { lock.lock(); latest = nil; lock.unlock() }
    func energy(at time: Double) -> Double? {
        guard lock.try() else { return nil }
        defer { lock.unlock() }
        guard let latest, abs(latest.time - time) < 0.5 else { return nil }
        return latest.energy
    }

    func parameters(for track: AVAssetTrack) -> AVMutableAudioMixInputParameters? {
        let retained = Unmanaged.passRetained(self)
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0, clientInfo: retained.toOpaque(),
            init: { _, info, storage in storage.pointee = info },
            finalize: { tap in Unmanaged<StreamingAudioEnergy>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release() },
            prepare: { tap, _, format in
                Unmanaged<StreamingAudioEnergy>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue().format = format.pointee
            }, unprepare: nil,
            process: { tap, frames, _, buffers, framesOut, flagsOut in
                var range = CMTimeRange.invalid
                let status = MTAudioProcessingTapGetSourceAudio(tap, frames, buffers, flagsOut, &range, framesOut)
                guard status == noErr else { framesOut.pointee = 0; return }
                let state = Unmanaged<StreamingAudioEnergy>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
                guard state.format.mFormatFlags & kAudioFormatFlagIsFloat != 0,
                      state.format.mBitsPerChannel == 32,
                      state.format.mFormatFlags & kAudioFormatFlagIsBigEndian == 0 else { return }
                var sum = 0.0, count = 0
                for buffer in UnsafeMutableAudioBufferListPointer(buffers) {
                    guard let data = buffer.mData else { continue }
                    let values = data.assumingMemoryBound(to: Float.self)
                    for index in stride(from: 0, to: Int(buffer.mDataByteSize) / 4, by: 8) {
                        sum += Double(values[index] * values[index]); count += 1
                    }
                }
                guard count > 0, state.lock.try() else { return }
                state.latest = (range.start.seconds, sqrt(sum / Double(count)))
                state.lock.unlock()
            })
        var tap: MTAudioProcessingTap?
        guard MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PreEffects, &tap) == noErr,
              let tap else { retained.release(); return nil }
        let parameters = AVMutableAudioMixInputParameters(track: track)
        parameters.audioTapProcessor = tap
        return parameters
    }
}
