import Foundation
import AVFoundation

@main
@MainActor
struct MediaChecks {
    static func image(bar: Int, fullWhite: Bool = false) -> CVPixelBuffer {
        var result: CVPixelBuffer?
        precondition(CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_32BGRA, nil, &result) == kCVReturnSuccess)
        let image = result!
        CVPixelBufferLockBaseAddress(image, [])
        let data = CVPixelBufferGetBaseAddress(image)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(image)
        for y in 0..<64 {
            for x in 0..<64 {
                let value: UInt8 = fullWhite ? 255 : ((bar..<(bar + 16)).contains(x) ? 200 : 10)
                let index = y * stride + x * 4
                data[index] = value; data[index + 1] = value; data[index + 2] = value; data[index + 3] = 255
            }
        }
        CVPixelBufferUnlockBaseAddress(image, [])
        return image
    }

    static func main() async {
        let service = VideoRhythmAnalyzer()
        let first = service.analyze(image(bar: 0), at: 0)
        precondition(first.movement == 0)
        let stationary = service.analyze(image(bar: 0), at: 0.1)
        precondition(stationary.movement == 0)
        let movement = service.analyze(image(bar: 20), at: 0.2)
        precondition(movement.movement > 0.01)
        let cut = service.analyze(image(bar: 0, fullWhite: true), at: 0.3)
        precondition(cut.movement == 0, "Full-frame cuts should not trigger movement")
        service.resetSamples()
        precondition(service.analyze(image(bar: 50), at: 10).movement == 0, "Seek resets frame history")
        let item = AVPlayerItem(asset: AVMutableComposition())
        service.attach(to: item)
        precondition(item.outputs.contains { $0 is AVPlayerItemVideoOutput })
        precondition(service.sample(at: .zero) == nil, "No decoded frames should report no sample")
        service.detach()
        precondition(item.outputs.isEmpty, "Output must detach on stop")
        // Feed real in-memory image differences to the bounded live meter; no file or network fixtures.
        var meter = LiveRhythmMeter()
        for frame in 0..<480 {
            let time = Double(frame) / 12
            meter.advance(to: time)
            meter.ingest(service.analyze(image(bar: frame % 12 < 6 ? 0 : 24), at: time))
        }
        precondition(meter.ready)
        precondition(meter.level != .stop)
        precondition(meter.samples.count <= 64)
        precondition((meter.samples.last!.time - meter.samples.first!.time) <= 4.01)
        print("In-memory streaming checks passed: moving/still frames, cut rejection, seek reset, output attachment/removal, no-frame fallback, bounded live classification")
    }
}
