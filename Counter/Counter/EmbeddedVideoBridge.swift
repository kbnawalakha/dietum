import Foundation

struct EmbeddedVideoEvent {
    enum Kind: String { case idle, frame, paused, blocked, seeking, playback }
    let kind: Kind
    let id: String
    let time: Double
    let area: Double
    let grid: [Double]?
    let isPlaying: Bool?

    init?(body: Any) {
        guard let body = body as? [String: Any], let raw = body["kind"] as? String,
              let kind = Kind(rawValue: raw) else { return nil }
        if kind == .idle {
            self.kind = kind; id = ""; time = 0; area = 0; grid = nil; isPlaying = nil; return
        }
        guard let id = body["id"] as? String, !id.isEmpty, id.utf8.count <= 100,
              let time = body["time"] as? Double, time.isFinite, (0...1e12).contains(time),
              let area = body["area"] as? Double, area.isFinite, (0...1e8).contains(area) else { return nil }
        if kind == .frame {
            guard let grid = body["grid"] as? [Double], grid.count == 256,
                  grid.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else { return nil }
            self.grid = grid
        } else { grid = nil }
        isPlaying = body["playing"] as? Bool
        self.kind = kind; self.id = id; self.time = time; self.area = area
    }
}

struct EmbeddedMotionUpdate {
    let kind: EmbeddedVideoEvent.Kind
    let sample: LiveRhythmSample?
    let reset: Bool
}

/// Selects one current player and retains only its tiny previous frame grid.
struct EmbeddedMotionRouter {
    private var activeID: String?
    private var activeArea = 0.0
    private var activePlaying = false
    private var lastSeen = -Double.infinity
    private var previous: [Double]?
    private var time: Double?

    mutating func reset() { self = EmbeddedMotionRouter() }

    mutating func receive(_ event: EmbeddedVideoEvent, now: Double) -> EmbeddedMotionUpdate? {
        if event.kind == .idle {
            guard now - lastSeen > 2 else { return nil }
            reset()
            return EmbeddedMotionUpdate(kind: .idle, sample: nil, reset: true)
        }
        let incomingPlaying = event.kind == .frame || (event.kind == .playback && event.isPlaying == true)
        let changed = activeID != event.id
        if changed, activeID != nil, now - lastSeen < 1 {
            if activePlaying && (!incomingPlaying || event.area <= activeArea * 1.5) { return nil }
            if !activePlaying && !incomingPlaying { return nil }
        }
        if changed { previous = nil; time = nil }
        activeID = event.id; activeArea = event.area; activePlaying = incomingPlaying; lastSeen = now
        guard event.kind == .frame, let grid = event.grid else {
            if event.kind != .paused { previous = nil; time = nil }
            return EmbeddedMotionUpdate(kind: event.kind, sample: nil, reset: changed || event.kind == .seeking || event.kind == .blocked)
        }
        if let time, event.time == time { return nil }
        let jumped = time.map { event.time < $0 || event.time - $0 > 0.75 } ?? false
        if jumped { previous = nil }
        let difference = previous.map { previous in
            zip(previous, grid).reduce(0.0) { $0 + abs($1.0 - $1.1) } / 256
        } ?? 0
        previous = grid; time = event.time
        return EmbeddedMotionUpdate(kind: .frame,
            sample: LiveRhythmSample(time: event.time, movement: difference > 0.45 ? 0 : difference, audio: nil),
            reset: changed || jumped)
    }
}

/// Isolated-world, per-frame adapter. Browser CORS/DRM restrictions are left intact.
enum EmbeddedVideoScript {
    static let source = #"""
    (() => {
      if (globalThis.__counterVideoBridge) return;
      globalThis.__counterVideoBridge = true;
      const bridge = globalThis.webkit.messageHandlers.counterMotion;
      const prefix = Math.random().toString(36).slice(2);
      const ids = new WeakMap();
      let sequence = 0, allowed = false, stopped = false, canvas = null, timer = null;
      let candidates = [], scannedAt = -Infinity, videoEnabled = true, playbackEnabled = false;
      addEventListener('pagehide', () => { stopped = true; clearTimeout(timer); timer = null; });
      addEventListener('pageshow', () => { if (stopped) { stopped = false; tick(); } });
      async function tick() {
        if (stopped) return;
        let payload = {kind: 'idle'}, delay = 500;
        const found = [];
        function collect(root) {
          found.push(...root.querySelectorAll('video'));
          for (const element of root.querySelectorAll('*')) if (element.shadowRoot) collect(element.shadowRoot);
        }
        if (performance.now() - scannedAt > 1000 || !candidates.some(v => v.isConnected)) {
          collect(document); candidates = found.slice(0, 32); scannedAt = performance.now();
        }
        const videos = candidates.filter(v => v.isConnected).filter(v => {
          const r = v.getBoundingClientRect();
          const style = getComputedStyle(v);
          return r.width >= 16 && r.height >= 16 && style.display !== 'none' && style.visibility !== 'hidden';
        });
        videos.sort((a, b) => Number(!b.paused && !b.ended) - Number(!a.paused && !a.ended) ||
          b.clientWidth * b.clientHeight - a.clientWidth * a.clientHeight);
        const video = videos[0];
        if (allowed && video && Number.isFinite(video.currentTime)) {
          if (!ids.has(video)) ids.set(video, prefix + '-' + (++sequence));
          const r = video.getBoundingClientRect();
          payload = {kind: 'paused', id: ids.get(video), time: video.currentTime,
                     area: Math.min(1e8, r.width * r.height), playing: !video.paused && !video.ended && !video.seeking && video.readyState >= 3};
          if (playbackEnabled) { payload.kind = 'playback'; delay = 100; }
          if (!videoEnabled) { /* state-only monitoring does not read media pixels or audio */ }
          else if (video.seeking) payload.kind = 'seeking';
          else if (video.mediaKeys || video.webkitKeys) payload.kind = 'blocked';
          else if (!video.paused && !video.ended && video.readyState >= 2) {
            try {
              if (!canvas) { canvas = document.createElement('canvas'); canvas.width = canvas.height = 16; }
              const context = canvas.getContext('2d', {willReadFrequently: true});
              context.drawImage(video, 0, 0, 16, 16);
              const pixels = context.getImageData(0, 0, 16, 16).data;
              const grid = new Array(256);
              for (let i = 0; i < 256; i++) grid[i] = (pixels[i * 4] + pixels[i * 4 + 1] + pixels[i * 4 + 2]) / 765;
              payload.kind = 'frame'; payload.grid = grid; delay = 84;
            } catch (_) {
              payload.kind = 'blocked'; canvas = null;
            }
          }
        }
        try { const reply = await bridge.postMessage(payload); allowed = reply.enabled === true; videoEnabled = reply.video !== false; playbackEnabled = reply.playback === true; }
        catch (_) { allowed = false; }
        if (!stopped) timer = setTimeout(tick, allowed ? delay : 500);
      }
      tick();
    })();
    """#
}
