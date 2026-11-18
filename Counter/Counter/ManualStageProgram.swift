import Foundation

enum StageDurationMode: String, CaseIterable { case normal = "Normal", random = "Random" }
enum BleepyEffect: Int, CaseIterable {
    case decrease, increase, complete, ultrafast
}

struct StageRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

/// Manual program state is numeric and in-memory only; no video/link history.
struct ManualStageProgram {
    enum Phase { case idle, stage, rest }
    private(set) var phase: Phase = .idle
    private(set) var elapsed = 0.0
    private(set) var stage = 0
    private(set) var level: RhythmLevel = .stop
    private(set) var stageActiveTime = 0.0
    private(set) var stageSlowTime = 0.0
    private(set) var activeTime = 0.0
    private(set) var ultraTime = 0.0
    private(set) var bleepCount = 0
    private(set) var lastBleep = ""
    private(set) var lastStageSlowFraction = 0.0
    private(set) var stageDuration = 0
    private(set) var segmentDuration = 0
    private(set) var segment = 0
    private(set) var lastBleepAt = -Double.infinity
    private(set) var breakDuration = 0
    private(set) var nextBleep = Double.infinity
    private(set) var forcedUltra: Int?
    private var mode: StageDurationMode = .normal
    private var rng = StageRandom(state: 1)
    private var stageEnd = 0.0
    private var beatEnd = 0.0
    private var restEnd = 0.0
    private var nextBlock = 0
    private var nextAdjustment = 0
    private var skipNext = false

    var active: Bool { phase != .idle }
    var remaining: Double { max(0, (phase == .rest ? restEnd : stageEnd) - elapsed) }
    var segmentRemaining: Double { phase == .stage ? max(0, min(beatEnd, stageEnd) - elapsed) : 0 }
    var slowChance: Double { max(0.2, 0.5 - Double(max(0, stage - 1)) * 0.05) }
    var ultraFraction: Double { activeTime > 0 ? ultraTime / activeTime : 0 }

    mutating func start(mode: StageDurationMode, seed: UInt64) {
        self = ManualStageProgram()
        self.mode = mode; rng = StageRandom(state: seed)
        scheduleBleep(); beginStage()
    }
    mutating func stop() { self = ManualStageProgram() }
    private mutating func draw(_ range: ClosedRange<Int>) -> Int { Int.random(in: range, using: &rng) }
    private mutating func scheduleBleep() {
        nextBleep = Double(nextBlock * 300 + draw(1...299)); nextBlock += 1
    }

    mutating func advance(by seconds: Double) {
        guard active, seconds.isFinite, seconds > 0 else { return }
        let target = elapsed + seconds
        while elapsed < target {
            let boundary: Double
            switch phase {
            case .idle: return
            case .rest: boundary = restEnd
            case .stage: boundary = min(stageEnd, beatEnd)
            }
            let next = min(target, boundary, nextBleep)
            let delta = max(0, next - elapsed)
            if phase == .stage {
                activeTime += delta; stageActiveTime += delta
                if level == .slow { stageSlowTime += delta }
                if level == .ultrafast { ultraTime += delta }
            }
            elapsed = next
            if elapsed >= nextBleep {
                bleepCount += 1
                applyBleepy(BleepyEffect(rawValue: draw(0...3))!)
                scheduleBleep()
            }
            if phase == .stage && elapsed >= stageEnd { finishStage() }
            else if phase == .stage && elapsed >= beatEnd { chooseBeat() }
            else if phase == .rest && elapsed >= restEnd { beginStage() }
        }
    }

    mutating func applyBleepy(_ effect: BleepyEffect) {
        guard active else { return }
        lastBleepAt = elapsed
        switch effect {
        case .decrease:
            lastBleep = "Bleepy: stage −30 seconds"
            if phase == .stage { stageEnd = max(elapsed, stageEnd - 30) }
            else { nextAdjustment -= 30 }
        case .increase:
            lastBleep = "Bleepy: stage +30 seconds"
            if phase == .stage { stageEnd += 30 }
            else { nextAdjustment += 30 }
        case .complete:
            lastBleep = "Bleepy: stage complete"
            if phase == .stage { finishStage() } else { skipNext = true }
        case .ultrafast:
            let duration = draw(15...30)
            forcedUltra = duration
            lastBleep = "Bleepy: Ultrafast \(duration)s queued"
        }
    }

    private mutating func beginStage() {
        stage += 1; segment = 0; stageActiveTime = 0; stageSlowTime = 0; level = .stop
        // Ten-second stage granularity avoids random 1–9s stages that cannot contain a valid beat.
        let base = draw(mode == .normal ? 12...24 : 0...24) * 10
        stageDuration = skipNext ? 0 : max(0, base + nextAdjustment)
        skipNext = false; nextAdjustment = 0
        phase = .stage; stageEnd = elapsed + Double(stageDuration)
        if stageDuration == 0 { finishStage() } else { chooseBeat() }
    }

    private mutating func finishStage() {
        lastStageSlowFraction = stageActiveTime > 0 ? stageSlowTime / stageActiveTime : 0
        phase = .rest; level = .stop
        breakDuration = draw(15...30); restEnd = elapsed + Double(breakDuration)
    }

    private mutating func chooseBeat() {
        let remaining = max(0, Int((stageEnd - elapsed).rounded()))
        guard remaining > 0 else { finishStage(); return }
        // Bleepy time reductions may intentionally shorten the last segment.
        let valid = (min(10, remaining)...min(30, remaining)).filter {
            remaining == $0 || remaining - $0 >= 10
        }
        let duration = valid[draw(0...(valid.count - 1))]
        let previous = level
        // Prefix budgets keep caps true even if Bleepy ends/shortens a stage unexpectedly.
        let slowBudget = max(0, (stageActiveTime - 5 * stageSlowTime) / 4)
        let ultraBudget = max(0, activeTime - 2 * ultraTime)
        if let forcedUltra, previous != .ultrafast, Double(forcedUltra) <= ultraBudget + 1e-8,
           remaining >= forcedUltra, remaining == forcedUltra || remaining - forcedUltra >= 10 {
            self.forcedUltra = nil
            level = .ultrafast; segmentDuration = forcedUltra
        } else {
            var others: [RhythmLevel] = [.normal, .fast]
            if previous != .ultrafast, Double(duration) <= ultraBudget + 1e-8 { others.append(.ultrafast) }
            others.removeAll { $0 == previous }
            let slowEligible = previous != .slow && Double(duration) <= slowBudget + 1e-8
            if slowEligible && Double.random(in: 0..<1, using: &rng) < slowChance { level = .slow }
            else { level = others[draw(0...(others.count - 1))] }
            segmentDuration = duration
        }
        segment += 1
        beatEnd = elapsed + Double(segmentDuration)
    }
}
