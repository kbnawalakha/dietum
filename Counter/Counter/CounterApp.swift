import SwiftUI
import AVKit
import Combine

@main
struct CounterApp: App {
    init() { VideoRhythmAnalyzer.removeLegacyDownloads() }
    var body: some Scene { WindowGroup { CounterView() } }
}

@MainActor
final class PlaybackModel: ObservableObject {
    @Published var input = ""
    @Published var url: URL?
    @Published var player: AVPlayer?
    @Published var error: String?
    @Published var webMode = false
    @Published var isLoading = false
    @Published var reloadID = UUID()
    private let resolver: any LinkResolving
    private var observation: NSKeyValueObservation?

    init(resolver: any LinkResolving = LinkResolver()) { self.resolver = resolver }

    func open(forceWebsite: Bool = false, forceNative: Bool = false) {
        do {
            let resolved = try resolver.resolve(input)
            stop()
            url = resolved
            webMode = !forceNative && (forceWebsite || !resolver.isDirectVideo(resolved))
            error = nil
            isLoading = true
            reloadID = UUID()
            if !webMode {
                let item = AVPlayerItem(url: resolved)
                player = AVPlayer(playerItem: item)
                observation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                    let status = item.status
                    Task { @MainActor [weak self] in
                        guard let self, self.player?.currentItem === item else { return }
                        if status == .readyToPlay { self.isLoading = false }
                        if status == .failed {
                            self.isLoading = false
                            self.error = "This stream couldn’t play. Try the website player or another link."
                        }
                    }
                }
                player?.play()
            }
        } catch { self.error = error.localizedDescription }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        player?.pause()
        player = nil
        isLoading = false
    }

    func close() {
        stop()
        url = nil
        input = ""
        error = nil
    }
}

struct CounterView: View {
    @StateObject private var model = PlaybackModel()
    @StateObject private var metronome = MetronomeModel()
    @StateObject private var guide = RhythmGuideModel()
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var editingLink: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your link. Your screen.")
                            .font(.largeTitle.bold())
                        Text("Open a video stream or watch through a website’s player.")
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 14) {
                        HStack {
                            Image(systemName: "link").foregroundStyle(.mint)
                            TextField("Paste a video or website link", text: $model.input)
                                .keyboardType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.go)
                                .focused($editingLink)
                                .onSubmit { play() }
                                .accessibilityLabel("Video or website URL")
                            PasteButton(payloadType: String.self) { values in
                                if let value = values.first { model.input = value }
                            }
                            .labelStyle(.iconOnly)
                            .accessibilityLabel("Paste video link")
                        }
                        .padding(14)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                        Button(action: play) {
                            Label("Open video", systemImage: "play.fill")
                                .font(.headline).frame(maxWidth: .infinity).padding(8)
                        }
                        .buttonStyle(.borderedProminent).tint(.mint).foregroundStyle(.black)
                        .disabled(model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if let url = model.url {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label(model.webMode ? "Website player" : "Video player", systemImage: "play.rectangle")
                                    .font(.headline)
                                Spacer()
                                Button("Close", systemImage: "xmark.circle.fill") { guide.reset(); metronome.stop(); model.close() }
                                    .labelStyle(.iconOnly).accessibilityLabel("Close player")
                            }
                            Text(url.host ?? "Video").font(.caption).foregroundStyle(.secondary)
                            if model.isLoading { ProgressView("Loading…").tint(.mint) }
                            Group {
                            if model.webMode {
                                WebsitePlayer(url: url, loading: $model.isLoading, error: $model.error)
                                    .id(model.reloadID)
                                    .frame(height: 430)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else if let player = model.player {
                                VideoPlayer(player: player)
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            }
                            .overlay(alignment: .topTrailing) {
                                if guide.live && guide.enabled {
                                    RhythmGuideOverlay(guide: guide)
                                } else {
                                    MetronomeOverlay(model: metronome)
                                }
                            }
                            if !model.webMode, let player = model.player {
                                RhythmGuideControls(guide: guide) {
                                    metronome.stop()
                                    guide.start(player: player)
                                }
                            }
                            HStack {
                                Button("Reload", systemImage: "arrow.clockwise") { model.open(forceWebsite: model.webMode, forceNative: !model.webMode) }
                                Spacer()
                                if model.webMode {
                                    Button("Try native player") { model.open(forceNative: true) }
                                } else {
                                    Button("Try website player") { model.open(forceWebsite: true) }
                                }
                            }.font(.subheadline)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "play.rectangle.on.rectangle")
                                .font(.system(size: 54)).foregroundStyle(.mint)
                            Text("Ready when you are").font(.title2.bold())
                            Text("Paste a link above to start watching here.")
                                .foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 48)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 24))
                    }
                    if let error = model.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange).font(.callout)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                    Label("Links aren’t saved. Closing the player clears the current link.", systemImage: "hand.raised")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Direct MP4, MOV and HLS streams use the iPhone player. Other links open inside Counter. Website restrictions, unsupported formats, or protected content may prevent playback. An internet connection is required.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20)
            }
            .background(Color(red: 0.035, green: 0.055, blue: 0.08))
            .navigationTitle("Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { editingLink = false } } }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { metronome.stop(); guide.suspend() }
        }
        .onChange(of: model.reloadID) { _, _ in guide.reset() }
        .onChange(of: guide.enabled) { _, enabled in if enabled { metronome.stop() } }
        .onDisappear { metronome.stop(); guide.reset() }
    }
    private func play() { editingLink = false; model.open() }
}
