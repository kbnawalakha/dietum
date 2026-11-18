import SwiftUI
import AVFoundation
import Combine

@MainActor
final class RhythmGuideModel: ObservableObject {
    @Published private(set) var live = false
    @Published private(set) var message: String?
    @Published private(set) var playing = false
    @Published private(set) var meter = LiveRhythmMeter()
    @Published var enabled = true {
        didSet {
            guard live else { return }
            meter.reset(); embeddedRouter.reset(); analyzer.detach(); lastFrameTime = nil
            if enabled, let item = player?.currentItem { analyzer.attach(to: item) }
        }
    }
    private var embedded = false
    private var embeddedRouter = EmbeddedMotionRouter()
    private let analyzer: any VideoRhythmAnalyzing
    private var player: AVPlayer?
    private var observer: Any?
    private var playbackStatus: NSKeyValueObservation?
    private var jumpObserver: NSObjectProtocol?
    private var lastFrameTime: Double?
    private var waitingSince: Double?

    init(analyzer: (any VideoRhythmAnalyzing)? = nil) { self.analyzer = analyzer ?? VideoRhythmAnalyzer() }

    func startEmbedded() {
        reset()
        embedded = true; live = true
    }

    func receiveEmbedded(_ event: EmbeddedVideoEvent) {
        guard embedded, live, enabled,
              let update = embeddedRouter.receive(event, now: ProcessInfo.processInfo.systemUptime) else { return }
        if update.reset { meter.reset() }
        switch update.kind {
        case .frame:
            guard let sample = update.sample else { return }
            playing = true; message = nil
            meter.advance(to: sample.time); meter.ingest(sample)
        case .paused:
            playing = false
        case .seeking:
            playing = false
        case .blocked:
            playing = false
            message = "This embedded player blocks video-frame access. Playback can continue; use manual rhythm or a direct video link."
        case .playback: return
        case .idle:
            playing = false
            message = "Play an embedded video to start tracking. Some website players restrict frame access."
        }
    }

    func start(player: AVPlayer) {
        reset()
        guard let item = player.currentItem else { return }
        self.player = player
        live = true
        analyzer.attach(to: item)
        playbackStatus = player.observe(\.timeControlStatus, options: [.new]) { [weak self, weak player] _, _ in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, self.player === player else { return }
                self.playing = player.timeControlStatus == .playing
            }
        }
        jumpObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemTimeJumped, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.meter.reset(); self?.analyzer.resetSamples()
                self?.lastFrameTime = nil; self?.waitingSince = nil
            }
        }
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0 / 30, preferredTimescale: 600), queue: .main) { [weak self, weak player] time in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, self.player === player else { return }
                self.playing = player.timeControlStatus == .playing
                guard self.enabled, self.playing, time.seconds.isFinite else { return }
                self.meter.advance(to: time.seconds)
                if let sample = self.analyzer.sample(at: time) {
                    self.lastFrameTime = time.seconds
                    self.waitingSince = nil
                    self.meter.ingest(sample)
                    self.message = nil
                } else {
                    if self.waitingSince == nil { self.waitingSince = time.seconds }
                    if time.seconds - (self.lastFrameTime ?? self.waitingSince ?? time.seconds) > 3 {
                        self.meter.reset()
                        self.message = "Video frames aren’t available for analysis. Try another stream or switch to manual tempo."
                    }
                }
            }
        }
    }

    func reset() {
        live = false
        if let observer { player?.removeTimeObserver(observer) }
        observer = nil
        playbackStatus?.invalidate(); playbackStatus = nil
        if let jumpObserver { NotificationCenter.default.removeObserver(jumpObserver) }
        jumpObserver = nil
        analyzer.detach(); player = nil; embedded = false; embeddedRouter.reset()
        meter.reset(); message = nil; playing = false
        lastFrameTime = nil; waitingSince = nil; enabled = true
    }

    func suspend() { enabled = false; playing = false }
}

struct RhythmGuideControls: View {
    @ObservedObject var guide: RhythmGuideModel
    let analyze: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if guide.live {
                Toggle("Live rhythm bar", isOn: $guide.enabled)
                Button("Stop live analysis") { guide.reset() }
                if guide.enabled && !guide.meter.ready && guide.message == nil {
                    Text(guide.playing ? "Learning movement as the video plays…" : "Play the video to learn its movement.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Button("Start live rhythm", systemImage: "waveform.path") { analyze() }
            }
            if let message = guide.message { Text(message).font(.callout).foregroundStyle(.orange) }
            Text("Analyzes the playing stream without creating video files. No links or analysis history are saved. The bar follows detected movement timing and waits when no steady rhythm is visible. Speed labels stay over 10 seconds; audio may refine labels but never drives the bar.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct RhythmBar: View {
    let position: Double
    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule().fill(.white.opacity(0.12))
            Capsule().fill(LinearGradient(colors: [.mint, .cyan], startPoint: .bottom, endPoint: .top))
                .frame(height: max(4, 108 * min(1, max(0, position))))
        }
        .frame(width: 22, height: 108)
        .overlay(Capsule().stroke(.white.opacity(0.25)))
        .accessibilityLabel("Rhythm bar")
        .accessibilityValue("\(Int(min(1, max(0, position)) * 100)) percent")
    }
}

struct RhythmGuideOverlay: View {
    @ObservedObject var guide: RhythmGuideModel
    var body: some View {
        VStack(spacing: 6) {
            Text(guide.meter.ready ? guide.meter.level.rawValue : "Learning")
                .font(.subheadline.bold())
            RhythmBar(position: guide.meter.position)
            if let bpm = guide.meter.measuredBPM, guide.meter.tracking {
                Text("≈ \(Int(bpm.rounded())) BPM").font(.caption.monospacedDigit())
            }
            Text(!guide.playing ? "Paused" : (guide.meter.tracking ? "Video locked" : "Waiting for rhythm")).font(.caption2)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(8)
        .allowsHitTesting(false)
    }
}
