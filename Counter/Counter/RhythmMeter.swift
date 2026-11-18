import Foundation

enum RhythmLevel: String, CaseIterable, Sendable {
    case stop = "Stop", superSlow = "Super slow", slow = "Slow", normal = "Normal", fast = "Fast", ultrafast = "Ultrafast"
    var targetBPM: Double {
        switch self {
        case .stop: return 0
        case .superSlow: return 20
        case .slow: return 40
        case .normal: return 80
        case .fast: return 120
        case .ultrafast: return 180
        }
    }
}

struct LiveRhythmSample {
    let time: Double
    let movement: Double
    let audio: Double?
}

/// Bounded rolling evidence; never retains media or an accumulated video timeline.
struct LiveRhythmMeter {
    private(set) var level: RhythmLevel = .stop
    private(set) var ready = false
    private(set) var phase = 0.0
    private(set) var measuredBPM: Double?
    private(set) var tracking = false
    private var motionPeak: Double?
    private var motionPeriod: Double?
    private(set) var heldFor = 0.0
    private(set) var samples: [LiveRhythmSample] = []
    private var lastTime: Double?
    private var started: Double?
    private var pending: RhythmLevel = .stop
    private var pendingSince = 0.0

    var position: Double { tracking ? 1 - abs(2 * phase - 1) : 0 }

    mutating func reset() { self = LiveRhythmMeter() }

    mutating func advance(to time: Double) {
        guard time.isFinite else { return }
        if let lastTime {
            let delta = time - lastTime
            // A seek/discontinuity starts a fresh observation window rather than using stale evidence.
            if delta < 0 || delta > 0.75 { reset() }
            else {
                heldFor += delta
                let oldPhase = phase
                updatePhase(at: time)
                let completedCycle = tracking && phase < oldPhase
                if ready, heldFor >= 11, pending != level, time - pendingSince >= 2,
                   (!tracking || completedCycle) {
                    level = pending; heldFor = 0
                }
            }
        }
        self.lastTime = time
    }

    mutating func ingest(_ sample: LiveRhythmSample) {
        guard sample.time.isFinite, sample.movement.isFinite else { return }
        if let previous = samples.last, sample.time <= previous.time { return }
        if started == nil { started = sample.time }
        samples.append(sample)
        samples.removeAll { sample.time - $0.time > 4 }
        // Upper bound even if a source delivers unexpectedly high frame frequency.
        if samples.count > 64 { samples.removeFirst(samples.count - 64) }
        guard let started, sample.time - started >= 3, samples.count >= 12 else { return }
        updateMotionClock(at: sample.time)
        let candidate = Self.classify(samples)
        if !ready {
            ready = true; level = candidate; pending = candidate
            pendingSince = sample.time; heldFor = 0
        } else if candidate != pending {
            pending = candidate; pendingSince = sample.time
        }
    }

    private mutating func updateMotionClock(at time: Double) {
        let movement = samples.map { RhythmSample(time: $0.time, strength: $0.movement) }
        let peaks = RhythmTimeline.peaks(movement, floor: 0.012, minimumGap: 0.25)
        guard peaks.count >= 3 else {
            motionPeriod = nil; motionPeak = nil; measuredBPM = nil; tracking = false
            return
        }
        let recent = Array(peaks.suffix(5))
        let gaps = zip(recent, recent.dropFirst()).map { $1 - $0 }
        let sorted = gaps.sorted()
        let median = sorted[sorted.count / 2]
        // Irregular/noisy movement is not a license to invent a regular beat.
        guard (0.25...2).contains(median), gaps.allSatisfy({ abs($0 - median) <= median * 0.3 }) else {
            motionPeriod = nil; motionPeak = nil; measuredBPM = nil; tracking = false
            return
        }
        motionPeriod = median
        motionPeak = recent.last
        measuredBPM = 60 / median
        updatePhase(at: time)
    }

    private mutating func updatePhase(at time: Double) {
        guard let motionPeak, let motionPeriod else { tracking = false; return }
        let elapsed = time - motionPeak
        // Interpolate at most ONE measured cycle. Never free-run through missing movement.
        guard elapsed >= 0, elapsed < motionPeriod else {
            tracking = false; phase = 0; measuredBPM = nil
            return
        }
        phase = elapsed / motionPeriod
        tracking = true
    }

    static func classify(_ samples: [LiveRhythmSample]) -> RhythmLevel {
        guard !samples.isEmpty else { return .stop }
        let mean = samples.reduce(0) { $0 + $1.movement } / Double(samples.count)
        guard mean >= 0.003 else { return .stop }
        let movement = samples.map { RhythmSample(time: $0.time, strength: $0.movement) }
        let peaks = RhythmTimeline.peaks(movement, floor: 0.012, minimumGap: 0.25)
        let audio = samples.compactMap { sample in sample.audio.map { RhythmSample(time: sample.time, strength: $0) } }
        let audioPeaks = RhythmTimeline.peaks(audio, floor: 0.015, minimumGap: 0.25)
        if peaks.count >= 2 {
            let movementBPM = Double(peaks.count - 1) * 60 / max(0.25, peaks.last! - peaks.first!)
            let audioBPM = audioPeaks.count >= 2 ? Double(audioPeaks.count - 1) * 60 / max(0.25, audioPeaks.last! - audioPeaks.first!) : movementBPM
            let bpm = 0.85 * movementBPM + 0.15 * min(movementBPM * 1.5, max(movementBPM * 0.5, audioBPM))
            if bpm < 60 { return .slow }
            if bpm < 100 { return .normal }
            if bpm < 150 { return .fast }
            return .ultrafast
        }
        if mean < 0.012 { return .slow }
        if mean < 0.035 { return .normal }
        if mean < 0.075 { return .fast }
        return .ultrafast
    }
}
