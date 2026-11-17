import Foundation
import AVFoundation

@main
struct MediaChecks {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let audioURL = root.appendingPathComponent("audio.wav")
        // A synthesized 120 BPM click track, not a network/media dependency.
        let format = AVAudioFormat(standardFormatWithSampleRate: 8000, channels: 1)!
        let audio = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 32000)!
        audio.frameLength = 32000
        for i in 0..<32000 {
            let phase = i % 4000
            audio.floatChannelData![0][i] = phase < 240 ? Float(sin(Double(phase) * 0.8) * exp(-Double(phase) / 80)) : 0
        }
        do {
            let file = try AVAudioFile(forWriting: audioURL, settings: format.settings)
            try file.write(from: audio)
        }
        let analyzer = VideoRhythmAnalyzer()
        let audioResult = try await analyzer.analyzeAsset(AVURLAsset(url: audioURL))
        precondition(audioResult.audio.count >= 6, "Click track should yield audio cues")
        precondition(audioResult.motion.isEmpty)
        let gaps = zip(audioResult.audio, audioResult.audio.dropFirst()).map { $1 - $0 }
        precondition(gaps.allSatisfy { abs($0 - 0.5) < 0.05 }, "120 BPM click intervals")

        let videoURL = root.appendingPathComponent("movement.mov")
        let writer = try AVAssetWriter(outputURL: videoURL, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 64, AVVideoHeightKey: 64])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
            sourcePixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                                         kCVPixelBufferWidthKey as String: 64, kCVPixelBufferHeightKey as String: 64])
        writer.add(input)
        precondition(writer.startWriting())
        writer.startSession(atSourceTime: .zero)
        for frame in 0..<120 {
            while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 1_000_000) }
            var pixel: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_32BGRA, nil, &pixel)
            let image = pixel!
            CVPixelBufferLockBaseAddress(image, [])
            let data = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
            let stride = CVPixelBufferGetBytesPerRow(image)
            // Repeated moving bar in a static scene.
            let left = frame % 15 < 3 ? 24 : 0
            for y in 0..<64 {
                for x in 0..<64 {
                    let value: UInt8 = (left..<(left + 16)).contains(x) ? 220 : 15
                    let index = y * stride + x * 4
                    data[index] = value; data[index + 1] = value; data[index + 2] = value; data[index + 3] = 255
                }
            }
            CVPixelBufferUnlockBaseAddress(image, [])
            precondition(adaptor.append(image, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)))
        }
        input.markAsFinished()
        await writer.finishWriting()
        precondition(writer.status == .completed)
        // URLSession downloads have temporary filenames, not the original video extension.
        let downloadedURL = root.appendingPathComponent(UUID().uuidString + ".tmp")
        try FileManager.default.moveItem(at: videoURL, to: downloadedURL)
        let mediaURL = root.appendingPathComponent(UUID().uuidString + ".mov")
        try FileManager.default.moveItem(at: downloadedURL, to: mediaURL)
        let videoResult = try await analyzer.analyzeAsset(AVURLAsset(url: mediaURL))
        precondition(!videoResult.motion.isEmpty, "Repeated movement should yield cues")
        precondition(videoResult.audio.isEmpty)
        let server = Process()
        let pipe = Pipe()
        server.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        server.arguments = ["-u", "-c", """
import http.server, os, sys, time
os.chdir(sys.argv[1])
class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args): pass
    def do_GET(self):
        if self.path in ('/large.mov', '/slow.mov'):
            self.send_response(200)
            self.send_header('Content-Length', str(200 * 1024 * 1024 if self.path == '/large.mov' else 1024))
            self.end_headers()
            if self.path == '/slow.mov': time.sleep(1)
            try: self.wfile.write(b'0' * 65536); self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError): pass
        else: super().do_GET()
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
print(server.server_port, flush=True)
server.serve_forever()
""", root.path]
        server.standardOutput = pipe
        server.standardError = FileHandle.nullDevice
        try server.run()
        defer { server.terminate(); server.waitUntilExit() }
        let port = String(data: pipe.fileHandleForReading.availableData, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = "http://127.0.0.1:" + port
        FileHandle.standardError.write(Data("Checking download decoding\n".utf8))
        let downloaded = try await analyzer.analyze(URL(string: base + "/" + mediaURL.lastPathComponent)!)
        precondition(!downloaded.motion.isEmpty, "End-to-end downloaded MOV should decode")
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: VideoRhythmAnalyzer.temporaryDirectory.path)
        precondition(leftovers.isEmpty)
        FileHandle.standardError.write(Data("Checking size cap\n".utf8))
        do {
            _ = try await analyzer.analyze(URL(string: base + "/large.mov")!)
            fatalError("Oversized download should fail")
        } catch RhythmAnalysisError.tooLarge { }
        FileHandle.standardError.write(Data("Checking HTTP error\n".utf8))
        do {
            _ = try await analyzer.analyze(URL(string: base + "/missing.mov")!)
            fatalError("HTTP error should fail")
        } catch RhythmAnalysisError.download { }
        let networkCancellation = Task { try await analyzer.analyze(URL(string: base + "/slow.mov")!) }
        try await Task.sleep(nanoseconds: 50_000_000)
        networkCancellation.cancel()
        do { _ = try await networkCancellation.value; fatalError("Download should cancel") }
        catch is CancellationError { }
        do {
            _ = try await analyzer.analyze(URL(string: "https://example.invalid/live.m3u8")!)
            fatalError("HLS analysis should be rejected before networking")
        } catch RhythmAnalysisError.unsupported { }
        let cancelled = Task {
            try Task.checkCancellation()
            return try await analyzer.analyzeAsset(AVURLAsset(url: mediaURL))
        }
        cancelled.cancel()
        do { _ = try await cancelled.value; fatalError("Cancellation should propagate") }
        catch is CancellationError { }
        print("Media checks passed: audio tempo, movement, missing tracks, temporary filenames, HTTP download/cleanup, size cap, HTTP errors, HLS rejection, decode/download cancellation")
    }
}
