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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !model.running)) { context in
                    let lit = model.running && context.date.timeIntervalSince(model.lastBeat) < 0.12
                    Circle().fill(lit ? Color.mint : Color.gray.opacity(0.5))
                        .frame(width: 14, height: 14)
                        .scaleEffect(lit && !reduceMotion ? 1.2 : 1)
                }.accessibilityHidden(true)
                Text("\(model.bpm) BPM").font(.subheadline.bold()).monospacedDigit()
                Button(model.running ? "Stop" : "Start", systemImage: model.running ? "stop.fill" : "play.fill") {
                    model.toggle()
                }.labelStyle(.iconOnly)
                    .accessibilityLabel(model.running ? "Stop metronome" : "Start metronome")
                Button("Tempo settings", systemImage: expanded ? "chevron.up" : "slider.horizontal.3") {
                    expanded.toggle()
                }.labelStyle(.iconOnly).accessibilityLabel("Tempo settings")
            }
            if expanded {
                HStack {
                    Button("Slower", systemImage: "minus.circle") { model.setTempo(model.bpm - 1) }
                        .labelStyle(.iconOnly).disabled(model.bpm == 30)
                    Slider(value: Binding(get: { Double(model.bpm) }, set: { model.setTempo(Int($0)) }), in: 30...240, step: 1)
                        .accessibilityLabel("Tempo in beats per minute")
                    Button("Faster", systemImage: "plus.circle") { model.setTempo(model.bpm + 1) }
                        .labelStyle(.iconOnly).disabled(model.bpm == 240)
                }
                HStack {
                    ForEach(1...4, id: \.self) { beat in
                        Circle().fill(model.beat == beat ? Color.mint : Color.gray.opacity(0.4))
                            .frame(width: 10, height: 10)
                    }
                    Spacer()
                    Toggle("Click", isOn: $model.soundEnabled).fixedSize()
                        .accessibilityLabel("Audible metronome clicks")
                }
                if let error = model.soundError { Text(error).font(.caption) }
            }
        }
        .font(.subheadline)
        .tint(.mint)
        .padding(12)
        .frame(maxWidth: expanded ? 290 : nil)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.15)))
        .padding(10)
    }
}
