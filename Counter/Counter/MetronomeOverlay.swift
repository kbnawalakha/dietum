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
    @Published var useStages = true
    @Published var stageMode: StageDurationMode = .normal
    @Published var bleepySound = true
    @Published private(set) var program = ManualStageProgram()
    @Published private(set) var stagePaused = false
    private var stageTicker: Task<Void, Never>?
    private var bleep: AVAudioPlayer?
    private var ticker: Task<Void, Never>?
    private var click: AVAudioPlayer?

    func setTempo(_ value: Int) {
        bpm = min(240, max(30, value))
        if running { start() }
    }

    var effectiveBPM: Double {
        guard program.active, program.phase == .stage, program.segmentDuration > 0 else { return Double(bpm) }
        let duration = Double(program.segmentDuration)
        return max(1, (duration * program.level.targetBPM / 60).rounded()) * 60 / duration
    }

    var level: RhythmLevel {
        if !running { return .stop }
        if bpm < 60 { return .slow }
        if bpm < 100 { return .normal }
        if bpm < 150 { return .fast }
        return .ultrafast
    }

    func select(_ level: RhythmLevel) {
        stop(); useStages = false
        if level == .stop { stop(); return }
        setTempo(Int(level.targetBPM))
        if !running { start() }
    }

    func toggle() {
        if useStages {
            if !program.active { startStages() }
            else if stagePaused { stagePaused = false; applyStageTempo() }
            else { stagePaused = true; stopBeat() }
        } else { running ? stop() : start() }
    }

    func startStages() {
        stop(); useStages = true
        program.start(mode: stageMode, seed: UInt64.random(in: 0...UInt64.max))
        applyStageTempo()
        stageTicker = Task { [weak self] in
            var last = ProcessInfo.processInfo.systemUptime
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
                let now = ProcessInfo.processInfo.systemUptime
                let delta = now - last; last = now
                guard let self, self.program.active else { return }
                if self.stagePaused { continue }
                let count = self.program.bleepCount
                self.program.advance(by: delta)
                self.applyStageTempo()
                if self.bleepySound && self.program.bleepCount > count { self.playBleepy() }
            }
        }
    }

    private func applyStageTempo() {
        guard program.phase == .stage else { stopBeat(); return }
        let tempo = Int(program.level.targetBPM)
        if bpm != tempo || !running { bpm = tempo; start() }
    }

    private func playBleepy() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            if bleep == nil { bleep = try AVAudioPlayer(data: Self.clickData(frequency: 880, duration: 0.2)) }
            bleep?.currentTime = 0; bleep?.volume = 0.8; bleep?.play()
        } catch { soundError = "Bleepy sound unavailable; its timer action still applies." }
    }

    func stop() {
        stageTicker?.cancel(); stageTicker = nil
        program.stop(); stagePaused = false
        bleep?.stop(); stopBeat()
    }

    private func stopBeat() {
        ticker?.cancel()
        ticker = nil
        running = false
        beat = 0
        click?.stop()
    }

    private func start() {
        stopBeat()
        running = true
        let clock = ContinuousClock()
        let interval = Duration.seconds(60.0 / effectiveBPM)
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

    private static func clickData(frequency: Double = 1500, duration: Double = 0.03) -> Data {
        let rate = 44100
        let count = Int(Double(rate) * duration)
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
            let envelope = exp(-time * (duration > 0.1 ? 14 : 160)) * min(1, Double(sample) / 30)
            number(Int16(sin(2 * .pi * frequency * time) * envelope * 24000))
        }
        return data
    }
}

struct MetronomeOverlay: View {
    @ObservedObject var model: MetronomeModel
    @State private var expanded = false
    private func clock(_ seconds: Double) -> String {
        let value = max(0, Int(seconds.rounded(.up)))
        return "\(value / 60):" + String(format: "%02d", value % 60)
    }
    private var title: String {
        if model.program.active { return model.program.phase == .rest ? "Break" : "Stage \(model.program.stage)" }
        return model.useStages ? "Manual stages" : model.level.rawValue
    }
    private var control: String {
        model.program.active ? (model.stagePaused ? "Resume" : "Pause") : (model.running ? "Stop" : "Start")
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Text(title).font(.subheadline.bold())
                Button(control, systemImage: control == "Pause" ? "pause.fill" : (control == "Stop" ? "stop.fill" : "play.fill")) {
                    model.toggle()
                }.labelStyle(.iconOnly).accessibilityLabel(control + " manual rhythm")
                Button("Manual settings", systemImage: "slider.horizontal.3") { expanded = true }.labelStyle(.iconOnly)
            }
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !model.running)) { context in
                let elapsed = max(0, context.date.timeIntervalSince(model.lastBeat))
                let phase = (elapsed * model.effectiveBPM / 60).truncatingRemainder(dividingBy: 1)
                RhythmBar(position: model.running ? 1 - abs(2 * phase - 1) : 0)
            }
            if model.program.active {
                Text(model.stagePaused ? "Paused" : "\(model.program.level.rawValue) · \(clock(model.program.remaining))")
                    .font(.caption.monospacedDigit())
                if model.program.phase == .stage {
                    Text("Change in \(clock(model.program.segmentRemaining))").font(.caption2.monospacedDigit())
                }
                if model.program.elapsed - model.program.lastBleepAt < 8 {
                    Text(model.program.lastBleep).font(.caption2).lineLimit(2).frame(maxWidth: 170)
                }
            } else { Text("\(model.running ? model.bpm : 0) BPM · Manual").font(.caption.monospacedDigit()) }
        }
        .tint(.mint).padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(8)
        .sheet(isPresented: $expanded) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Manual rhythm").font(.title2.bold())
                    Picker("Program", selection: $model.useStages) {
                        Text("Stages").tag(true); Text("Fixed tempo").tag(false)
                    }.pickerStyle(.segmented)
                    .onChange(of: model.useStages) { _, _ in model.stop() }
                    if model.useStages {
                        Picker("Stage duration", selection: $model.stageMode) {
                            ForEach(StageDurationMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented).disabled(model.program.active)
                        Text("Normal: 2–4 min · Random: 0–4 min\n10–30s speed segments · 15–30s breaks\nSlow ≤20% per stage · Ultrafast ≤50% active time")
                            .font(.callout).foregroundStyle(.secondary)
                        if model.program.active {
                            Text("Stage \(model.program.stage) · \(clock(model.program.remaining)) remaining")
                            Text("Slow \(Int(model.program.stageSlowTime))s / \(Int(model.program.stageActiveTime))s · Ultrafast \(Int(model.program.ultraFraction * 100))%")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        HStack {
                            Button(control) { model.toggle() }.buttonStyle(.borderedProminent)
                            if model.program.active { Button("End program") { model.stop() } }
                        }
                        Toggle("Bleepy sound", isOn: $model.bleepySound)
                        Text("One random Bleepy per five-minute block: −30s, +30s, stage complete, or 15–30s Ultrafast. Ultrafast waits for an eligible segment and available time under the cap.")
                            .font(.caption).foregroundStyle(.secondary)
                        if !model.program.lastBleep.isEmpty { Text(model.program.lastBleep).font(.callout).foregroundStyle(.mint) }
                    } else {
                        Text("\(model.bpm) BPM").font(.headline)
                        HStack(spacing: 12) {
                            ForEach(RhythmLevel.allCases, id: \.self) { level in
                                Button(level.rawValue) { model.select(level) }.font(.caption)
                            }
                        }
                        Slider(value: Binding(get: { Double(model.bpm) }, set: { model.setTempo(Int($0)) }), in: 30...240, step: 1)
                            .accessibilityLabel("Tempo in beats per minute")
                        Button(control) { model.toggle() }
                    }
                    Toggle("Beat clicks", isOn: $model.soundEnabled)
                    if let error = model.soundError { Text(error).font(.caption) }
                    Button("Done") { expanded = false }
                }.padding(24)
            }.tint(.mint).presentationDetents([.medium, .large])
        }
    }
}
