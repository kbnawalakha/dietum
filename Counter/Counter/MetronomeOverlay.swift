import SwiftUI
import AVFoundation
import Combine

@MainActor
final class MetronomeModel: ObservableObject {
    @Published private(set) var bpm = 120
    @Published private(set) var running = false
    @Published private(set) var beat = 0
    @Published private(set) var lastBeat = Date.distantPast
    @Published var soundEnabled = false
    @Published private(set) var soundError: String?
    private var ticker: Task<Void, Never>?
    private var click: AVAudioPlayer?

    func setTempo(_ value: Int) {
        bpm = min(240, max(30, value))
        if running { start() }
    }

    var level: RhythmLevel {
        if !running { return .stop }
        if bpm < 60 { return .slow }
        if bpm < 100 { return .normal }
        if bpm < 150 { return .fast }
        return .ultrafast
    }

    func select(_ level: RhythmLevel) {
        if level == .stop { stop(); return }
        setTempo(Int(level.targetBPM))
        if !running { start() }
    }

    func toggle() { running ? stop() : start() }

    func stop() {
        ticker?.cancel()
        ticker = nil
        running = false
        beat = 0
        click?.stop()
    }

    private func start() {
        stop()
        running = true
        let clock = ContinuousClock()
        let interval = Duration.seconds(60.0 / Double(bpm))
        ticker = Task { [weak self] in
            var deadline = clock.now
            while !Task.isCancelled {
                guard let self else { return }
                self.beat = self.beat % 4 + 1
                self.lastBeat = Date()
                if self.soundEnabled { self.playClick() }
                deadline += interval
                // Drop missed beats after a stall instead of playing a burst.
                if deadline < clock.now { deadline = clock.now + interval }
                do { try await clock.sleep(until: deadline) } catch { return }
            }
        }
    }

    private func playClick() {
        do {
            if click == nil {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                click = try AVAudioPlayer(data: Self.clickData())
                click?.prepareToPlay()
            }
            click?.currentTime = 0
            click?.volume = beat == 1 ? 0.8 : 0.45
            click?.play()
            soundError = nil
        } catch {
            soundEnabled = false
            soundError = "Click sound unavailable. Visual beats still work."
        }
    }

    private static func clickData() -> Data {
        let rate = 44100
        let count = 1323
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func number<T: FixedWidthInteger>(_ value: T) {
            var little = value.littleEndian
            withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
        }
        text("RIFF"); number(UInt32(36 + count * 2)); text("WAVEfmt ")
        number(UInt32(16)); number(UInt16(1)); number(UInt16(1))
        number(UInt32(rate)); number(UInt32(rate * 2)); number(UInt16(2)); number(UInt16(16))
        text("data"); number(UInt32(count * 2))
        for sample in 0..<count {
            let time = Double(sample) / Double(rate)
            let envelope = exp(-time * 160) * min(1, Double(sample) / 30)
            number(Int16(sin(2 * .pi * 1500 * time) * envelope * 24000))
        }
        return data
    }
}

struct MetronomeOverlay: View {
    @ObservedObject var model: MetronomeModel
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(model.level.rawValue).font(.subheadline.bold())
                Button(model.running ? "Stop" : "Start", systemImage: model.running ? "stop.fill" : "play.fill") {
                    model.toggle()
                }.labelStyle(.iconOnly)
                    .accessibilityLabel(model.running ? "Stop metronome" : "Start metronome")
                Button("Tempo settings", systemImage: "slider.horizontal.3") { expanded = true }
                    .labelStyle(.iconOnly)
            }
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !model.running)) { context in
                let elapsed = max(0, context.date.timeIntervalSince(model.lastBeat))
                let phase = (elapsed * Double(model.bpm) / 60).truncatingRemainder(dividingBy: 1)
                RhythmBar(position: model.running ? 1 - abs(2 * phase - 1) : 0)
            }
            Text("\(model.running ? model.bpm : 0) BPM · Manual").font(.caption.monospacedDigit())
        }
        .tint(.mint)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(8)
        .sheet(isPresented: $expanded) {
            VStack(spacing: 18) {
                Text("Manual tempo · \(model.bpm) BPM").font(.headline)
                HStack(spacing: 12) {
                    ForEach(RhythmLevel.allCases, id: \.self) { level in
                        Button(level.rawValue) { model.select(level) }.font(.caption)
                    }
                }
                HStack {
                    Button("Slower", systemImage: "minus.circle") { model.setTempo(model.bpm - 1) }
                        .labelStyle(.iconOnly).disabled(model.bpm == 30)
                    Slider(value: Binding(get: { Double(model.bpm) }, set: { model.setTempo(Int($0)) }), in: 30...240, step: 1)
                        .accessibilityLabel("Tempo in beats per minute")
                    Button("Faster", systemImage: "plus.circle") { model.setTempo(model.bpm + 1) }
                        .labelStyle(.iconOnly).disabled(model.bpm == 240)
                }
                Toggle("Audible clicks", isOn: $model.soundEnabled)
                if let error = model.soundError { Text(error).font(.caption) }
                Button("Done") { expanded = false }
            }
            .padding(24).tint(.mint)
            .presentationDetents([.height(300)])
        }
    }
}
