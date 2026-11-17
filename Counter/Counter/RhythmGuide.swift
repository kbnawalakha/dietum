import SwiftUI
import AVFoundation
import Combine

@MainActor
final class RhythmGuideModel: ObservableObject {
    @Published private(set) var analyzing = false
    @Published private(set) var timeline: RhythmTimeline?
    @Published private(set) var message: String?
    @Published private(set) var cue: Int?
    @Published private(set) var playbackTime = 0.0
    @Published var enabled = true
    @Published var source: RhythmSource = .combined {
        didSet { selectedCues = timeline?.cues(for: source) ?? []; cue = nil }
    }
    private(set) var selectedCues: [Double] = []
    private let analyzer: any VideoRhythmAnalyzing
    private var work: Task<Void, Never>?
    private var player: AVPlayer?
    private var observer: Any?
    private var playbackStatus: NSKeyValueObservation?
    private var generation = UUID()

    init(analyzer: any VideoRhythmAnalyzing = VideoRhythmAnalyzer()) { self.analyzer = analyzer }

    func analyze(url: URL, player: AVPlayer) {
        reset()
        self.player = player
        analyzing = true
        let generation = self.generation
        work = Task { [weak self, analyzer] in
            do {
                let result = try await analyzer.analyze(url)
                try Task.checkCancellation()
                guard let self, self.generation == generation else { return }
                self.timeline = result
                self.selectedCues = result.cues(for: self.source)
                self.analyzing = false
                self.follow(player)
            } catch {
                guard let self, self.generation == generation, !Task.isCancelled else { return }
                self.analyzing = false
                // Never display underlying network errors that may contain the source URL.
                self.message = (error as? RhythmAnalysisError)?.errorDescription
                    ?? "Analysis couldn’t finish. Try another direct video or use manual tempo."
            }
        }
    }

    func reset() {
        generation = UUID()
        work?.cancel()
        work = nil
        if let observer { player?.removeTimeObserver(observer) }
        observer = nil
        playbackStatus?.invalidate()
        playbackStatus = nil
        player = nil
        timeline = nil
        selectedCues = []
        message = nil
        cue = nil
        playbackTime = 0
        analyzing = false
        enabled = true
    }

    func suspend() { enabled = false; cue = nil }

    private func follow(_ player: AVPlayer) {
        playbackStatus = player.observe(\.timeControlStatus, options: [.new]) { [weak self, weak player] _, _ in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, self.player === player else { return }
                if player.timeControlStatus != .playing { self.cue = nil }
            }
        }
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0 / 30, preferredTimescale: 600), queue: .main) { [weak self, weak player] time in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, self.player === player else { return }
                self.playbackTime = time.seconds
                self.cue = RhythmTimeline.currentCue(in: self.selectedCues, at: time.seconds,
                    playing: self.enabled && player.timeControlStatus == .playing)
            }
        }
    }

    var nextCue: String {
        guard let next = selectedCues.first(where: { $0 > playbackTime }) else { return "No upcoming cues" }
        return String(format: "Next in %.1fs", max(0, next - playbackTime))
    }
}

struct RhythmGuideControls: View {
    @ObservedObject var guide: RhythmGuideModel
    let analyze: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if guide.analyzing {
                HStack {
                    ProgressView("Analyzing audio and movement…")
                    Spacer()
                    Button("Cancel") { guide.reset() }
                }
            } else {
                Button(guide.timeline == nil ? "Analyze video rhythm" : "Analyze again", systemImage: "waveform.path") { analyze() }
            }
            if let timeline = guide.timeline {
                Picker("Follow", selection: $guide.source) {
                    ForEach(RhythmSource.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                Toggle("Video-synchronized guide", isOn: $guide.enabled)
                Text("\(timeline.audio.count) audio cues · \(timeline.motion.count) movement cues")
                    .font(.caption).foregroundStyle(.secondary)
                if guide.selectedCues.isEmpty {
                    Text("No clear cues for this source. Select another source or use manual tempo.")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
            if let message = guide.message { Text(message).font(.callout).foregroundStyle(.orange) }
            Text("Estimated timing cues, not action recognition. Analysis temporarily downloads up to 150 MB; files must be 10 minutes or shorter. No links or results are saved.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct RhythmGuideOverlay: View {
    @ObservedObject var guide: RhythmGuideModel
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(guide.cue == nil ? "Wait" : "Move", systemImage: guide.cue == nil ? "circle" : "circle.fill")
                .font(.headline).foregroundStyle(guide.cue == nil ? .white : .mint)
            Text(guide.source.rawValue + " · Video sync").font(.caption)
            if let bpm = RhythmTimeline.estimatedBPM(in: guide.selectedCues, at: guide.playbackTime) {
                Text("≈ \(bpm) BPM").font(.caption.monospacedDigit())
            }
            Text(guide.nextCue).font(.caption.monospacedDigit())
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(10)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
    }
}
