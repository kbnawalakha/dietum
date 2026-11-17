import SwiftUI
import AVFoundation
import Combine

@MainActor
final class RhythmGuideModel: ObservableObject {
    @Published private(set) var analyzing = false
    @Published private(set) var timeline: RhythmTimeline?
    @Published private(set) var message: String?
    @Published private(set) var sections: [RhythmSection] = []
    @Published private(set) var playing = false
    @Published private(set) var playbackTime = 0.0
    @Published var enabled = true
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
                self.sections = RhythmMeter.sections(for: result)
                if self.sections.isEmpty { self.message = "The bar guide needs a video longer than 10 seconds so each level can last more than 10 seconds." }
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
        sections = []
        message = nil
        playing = false
        playbackTime = 0
        analyzing = false
        enabled = true
    }

    func suspend() { enabled = false; playing = false }

    private func follow(_ player: AVPlayer) {
        playbackStatus = player.observe(\.timeControlStatus, options: [.new]) { [weak self, weak player] _, _ in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, self.player === player else { return }
                self.playing = player.timeControlStatus == .playing
            }
        }
        observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0 / 30, preferredTimescale: 600), queue: .main) { [weak self, weak player] time in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, self.player === player else { return }
                self.playbackTime = time.seconds
                self.playing = player.timeControlStatus == .playing
            }
        }
    }

    var section: RhythmSection? {
        sections.first { playbackTime >= $0.start && playbackTime < $0.end }
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
            if !guide.sections.isEmpty {
                Toggle("Video-synchronized bar", isOn: $guide.enabled)
                Text("Movement-led · Full video · Levels held over 10 seconds")
                    .font(.caption).foregroundStyle(.secondary)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(guide.sections.enumerated()), id: \.offset) { _, section in
                            Text("\(Int(section.start))–\(Int(section.end))s \(section.level.rawValue)")
                                .font(.caption).padding(6).background(.white.opacity(0.08), in: Capsule())
                        }
                    }
                }
            }
            if let message = guide.message { Text(message).font(.callout).foregroundStyle(.orange) }
            Text("Movement-led estimates, not action recognition. Analysis temporarily downloads up to 150 MB; files must be 10 minutes or shorter. No links or results are saved.")
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
        let section = guide.section
        VStack(spacing: 6) {
            Text(section?.level.rawValue ?? "Stop").font(.subheadline.bold())
            RhythmBar(position: section?.barPosition(at: guide.playbackTime) ?? 0)
            if let section, section.level != .stop {
                Text("\(Int(section.bpm.rounded())) BPM").font(.caption.monospacedDigit())
            }
            Text(guide.playing ? "Video sync" : "Paused").font(.caption2)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(8)
        .allowsHitTesting(false)
    }
}
