import SwiftUI
import AVFoundation
import Combine

@MainActor
final class MetronomeModel: ObservableObject {
    @Published private(set) var bpm = 120
    @Published private(set) var running = false
    @Published private(set) var beat = 0
    @Published private(set) var lastBeat = Date.distantPast
    @Published var soundEnabled = true
    @Published private(set) var soundError: String?
    @Published var useStages = true
    @Published var stageMode: StageDurationMode = .normal
    @Published var bleepySound = true
    @Published private(set) var program = ManualStageProgram()
    @Published private(set) var stagePaused = false
    @Published var fixedTempo = 80.0
    @Published private(set) var playbackGate = ManualPlaybackGate()
    private weak var videoPlayer: AVPlayer?
    private var sourceIsEmbedded = false
    private var embeddedPlaybackRouter = EmbeddedMotionRouter()
    private var lastAppliedSegment = -1
    private var stageTicker: Task<Void, Never>?
    private var bleep: AVAudioPlayer?
    private var ticker: Task<Void, Never>?
    private var click: AVAudioPlayer?

    func configureVideoPlayback(player: AVPlayer?) {
        stop(); videoPlayer = player; sourceIsEmbedded = player == nil; playbackGate.reset()
    }

    func receiveEmbeddedPlayback(_ event: EmbeddedVideoEvent) {
        guard sourceIsEmbedded, program.active, let update = embeddedPlaybackRouter.receive(event, now: ProcessInfo.processInfo.systemUptime) else { return }
        if update.reset { playbackGate.reset() }
        playbackGate.update(playing: event.kind != .idle && event.isPlaying == true, now: ProcessInfo.processInfo.systemUptime)
        if !playbackGate.playing { stopBeat(); bleep?.stop() }
    }

    private func refreshPlaybackGate() {
        let now = ProcessInfo.processInfo.systemUptime
        if let player = videoPlayer {
            playbackGate.update(playing: player.timeControlStatus == .playing, now: now)
        } else { playbackGate.expire(at: now) }
    }

    var playbackMessage: String? {
        program.active && !playbackGate.playing ? "Waiting for video playback" : nil
    }

    private var targetTempo: Double {
        program.level.targetBPM * (useStages ? 1 : fixedTempo / 80)
    }

    var effectiveBPM: Double {
        guard program.active, (program.phase == .stage || program.overrideSegment), program.segmentDuration > 0 else { return Double(bpm) }
        let duration = Double(program.segmentDuration)
        return max(1, (duration * targetTempo / 60).rounded()) * 60 / duration
    }

    var level: RhythmLevel { program.active ? program.level : .stop }

    func toggle() {
        if !program.active { startStages() }
        else if stagePaused { stagePaused = false; refreshPlaybackGate(); applyStageTempo() }
        else { stagePaused = true; stopBeat(); bleep?.stop() }
    }

    func startStages() {
        stop()
        program.start(mode: stageMode, seed: UInt64.random(in: 0...UInt64.max), style: useStages ? .varied : .consistent)
        refreshPlaybackGate()
        applyStageTempo()
        stageTicker = Task { [weak self] in
            var last = ProcessInfo.processInfo.systemUptime
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
                let now = ProcessInfo.processInfo.systemUptime
                let delta = now - last; last = now
                guard let self, self.program.active else { return }
                self.refreshPlaybackGate()
                if self.stagePaused || !self.playbackGate.playing { self.stopBeat(); self.bleep?.stop(); continue }
                let count = self.program.bleepCount
                self.program.advance(by: delta)
                self.applyStageTempo()
                if self.bleepySound && self.program.bleepCount > count { self.playBleepy() }
                if !self.program.active { return }
            }
        }
    }

    private func applyStageTempo() {
        guard !stagePaused, playbackGate.playing, (program.phase == .stage || program.overrideSegment) else { stopBeat(); return }
        let tempo = Int(targetTempo.rounded())
        let key = program.stage * 1000 + program.segment
        if bpm != tempo || !running || lastAppliedSegment != key {
            bpm = tempo; lastAppliedSegment = key; start()
        }
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
        program.stop(); stagePaused = false; lastAppliedSegment = -1
        playbackGate.reset(); embeddedPlaybackRouter.reset()
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
            click?.volume = beat == 1 ? 0.22 : 0.14
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
        if model.program.overrideSegment { return "Bleepy" }
        if model.program.active { return model.program.phase == .rest ? "Break" : "Stage \(model.program.stage)/\(model.program.stageCount)" }
        return model.program.phase == .finished ? "Complete" : "Manual stages"
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
            if model.program.wheelVisible, let effect = model.program.pendingBleepy ?? model.program.selectedBleepy {
                BleepyWheelView(effect: effect, progress: model.program.wheelProgress,
                    spinning: model.program.spinning, message: model.program.lastBleep)
            } else {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !model.running)) { context in
                let elapsed = max(0, context.date.timeIntervalSince(model.lastBeat))
                let phase = (elapsed * model.effectiveBPM / 60).truncatingRemainder(dividingBy: 1)
                RhythmBar(position: model.running ? 1 - abs(2 * phase - 1) : 0)
            }
            if model.program.active {
                Text(model.stagePaused ? "Paused" : model.program.level.rawValue)
                    .font(.caption.monospacedDigit())
                if model.program.stageCountdownVisible {
                    Text("Time remaining: \(clock(model.program.remaining))")
                        .font(.caption.monospacedDigit()).accessibilityLabel("Stage time remaining \(clock(model.program.remaining))")
                }
                if model.program.elapsed - model.program.lastBleepAt < 8 {
                    Text(model.program.lastBleep).font(.caption2).lineLimit(2).frame(maxWidth: 170)
                }
            } else { Text("15–20 min · 5–6 stages").font(.caption) }
            }
            if let message = model.playbackMessage { Text(message).font(.caption2).frame(maxWidth: 170).lineLimit(3) }
        }
        .tint(.mint).padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16)).padding(8)
        .sheet(isPresented: $expanded) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Manual rhythm").font(.title2.bold())
                    if model.program.wheelVisible, let effect = model.program.pendingBleepy ?? model.program.selectedBleepy {
                        BleepyWheelView(effect: effect, progress: model.program.wheelProgress,
                            spinning: model.program.spinning, message: model.program.lastBleep)
                            .frame(maxWidth: .infinity)
                    }
                    Picker("Program", selection: $model.useStages) {
                        Text("Stages").tag(true); Text("Fixed tempo").tag(false)
                    }.pickerStyle(.segmented)
                    .onChange(of: model.useStages) { _, _ in model.stop() }
                    if !model.useStages {
                        Text("Consistent stage tempo: \(Int(model.fixedTempo)) BPM").font(.headline)
                        Slider(value: $model.fixedTempo, in: 40...100, step: 1).disabled(model.program.active)
                            .accessibilityLabel("Consistent stage base tempo")
                    }
                    Picker("Stage duration", selection: $model.stageMode) {
                        ForEach(StageDurationMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).disabled(model.program.active)
                    Text("Normal plan: 15–20 min · 5–6 varying stages\n15–30s breaks · Normal Slow ≤20% per stage\nNormal stages start below Ultra and finish Ultra; Bleepy is exempt.")
                        .font(.callout).foregroundStyle(.secondary)
                    if model.program.active {
                        Text("Stage \(model.program.stage)/\(model.program.stageCount)")
                        if model.program.stageCountdownVisible {
                            Text("Time remaining: \(clock(model.program.remaining))").monospacedDigit()
                        }
                    }
                    if let message = model.playbackMessage { Text(message).font(.callout).foregroundStyle(.orange) }
                    HStack {
                        Button(control) { model.toggle() }.buttonStyle(.borderedProminent)
                        if model.program.active { Button("End program") { model.stop() } }
                    }
                    Toggle("Bleepy sound", isOn: $model.bleepySound)
                    Text("Bleepy spins every random 1–5 minutes, during any stage, beat or break. The wheel reveals an outcome after three seconds. Bleepy adds ±10/20/30s, −40s, random +10–40s, completion, immediate Ultra or 30s Super slow. Bleepy ignores normal time/cap/closing rules. No playing video freezes the program; mute does not.")
                        .font(.caption).foregroundStyle(.secondary)
                    if !model.program.lastBleep.isEmpty { Text(model.program.lastBleep).font(.callout).foregroundStyle(.mint) }
                    DisclosureGroup("Wheel outcomes") {
                        ForEach(Array(BleepyEffect.allCases.enumerated()), id: \.offset) { index, effect in
                            Text("\(index + 1). \(effect.title)").font(.callout)
                        }
                    }
                    Toggle("Soft beat clicks", isOn: $model.soundEnabled)
                    if let error = model.soundError { Text(error).font(.caption) }
                    Button("Done") { expanded = false }
                }.padding(24)
            }.tint(.mint).presentationDetents([.medium, .large])
        }
    }
}
