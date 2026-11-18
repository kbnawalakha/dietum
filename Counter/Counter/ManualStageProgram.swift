import Foundation

enum StageDurationMode: String, CaseIterable { case normal = "Normal", random = "Random" }
enum ManualProgramStyle { case varied, consistent }
enum BleepyEffect: Int, CaseIterable {
    case decrease, increase, complete, ultrafast
    case superSlow, increase10, increase20, decrease10, decrease20, decrease40, randomIncrease

    var title: String {
        switch self {
        case .decrease: return "−30 seconds"
        case .increase: return "+30 seconds"
        case .complete: return "Stage complete"
        case .ultrafast: return "Ultrafast · 15–30s"
        case .superSlow: return "Super slow · 30s"
        case .increase10: return "+10 seconds"
        case .increase20: return "+20 seconds"
        case .decrease10: return "−10 seconds"
        case .decrease20: return "−20 seconds"
        case .decrease40: return "−40 seconds"
        case .randomIncrease: return "Random +10–40s"
        }
    }

    var adjustment: Int? {
        switch self {
        case .decrease: return -30
        case .increase: return 30
        case .increase10: return 10
        case .increase20: return 20
        case .decrease10: return -10
        case .decrease20: return -20
        case .decrease40: return -40
        default: return nil
        }
    }
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
    enum Phase { case idle, stage, rest, finished }
    private(set) var stageCount = 0
    private(set) var totalDuration = 0
    private(set) var stageLengths: [Int] = []
    private(set) var closingLengths: [Int] = []
    private(set) var closing = false
    private var rests: [Int] = []
    private var style: ManualProgramStyle = .varied
    private var stageStart = 0.0
    private(set) var phase: Phase = .idle
    private(set) var elapsed = 0.0
    private(set) var stage = 0
    private(set) var level: RhythmLevel = .stop
    private(set) var stageActiveTime = 0.0
    private(set) var stageSlowTime = 0.0
    private(set) var activeTime = 0.0
    private(set) var ultraTime = 0.0
    private(set) var bleepCount = 0
    private(set) var resolvedBleepCount = 0
    private(set) var lastBleep = ""
    private(set) var lastStageSlowFraction = 0.0
    private(set) var stageDuration = 0
    private(set) var segmentDuration = 0
    private(set) var segment = 0
    private(set) var lastBleepAt = -Double.infinity
    private(set) var breakDuration = 0
    private(set) var nextBleep = Double.infinity
    private(set) var overrideSegment = false
    private var restStart = 0.0
    private var mode: StageDurationMode = .normal
    private var rng = StageRandom(state: 1)
    private var stageEnd = 0.0
    private var beatEnd = 0.0
    private var restEnd = 0.0
    static let wheelDuration = 3.0
    private(set) var pendingBleepy: BleepyEffect?
    private(set) var selectedBleepy: BleepyEffect?
    private(set) var wheelStarted = -Double.infinity
    private var wheelSettlesAt = Double.infinity
    var spinning: Bool { pendingBleepy != nil }
    var wheelProgress: Double { spinning ? min(1, max(0, (elapsed - wheelStarted) / Self.wheelDuration)) : 1 }
    var wheelVisible: Bool { spinning || (selectedBleepy != nil && elapsed - lastBleepAt < 5) }

    var active: Bool { phase == .stage || phase == .rest }
    var sessionRemaining: Double { max(0, Double(totalDuration) - elapsed) }
    var remaining: Double { max(0, (phase == .rest ? restEnd : stageEnd) - elapsed) }
    var segmentRemaining: Double { phase == .stage ? max(0, min(beatEnd, stageEnd) - elapsed) : 0 }
    var slowChance: Double { max(0.2, 0.5 - 0.3 * Double(max(0, stage - 1)) / Double(max(1, stageCount - 1))) }
    var ultraFraction: Double { activeTime > 0 ? ultraTime / activeTime : 0 }

    mutating func start(mode: StageDurationMode, seed: UInt64, style: ManualProgramStyle = .varied, bleepyEnabled: Bool = true) {
        self = ManualStageProgram()
        self.mode = mode; self.style = style; rng = StageRandom(state: seed)
        stageCount = draw(5...6); totalDuration = draw(900...1200)
        rests = (0..<(stageCount - 1)).map { _ in draw(15...30) }
        var previous = 10
        for index in 0..<stageCount {
            let target = 10 + 20 * index / (stageCount - 1)
            let length = draw(max(previous, max(10, target - 2))...min(30, target + 3))
            closingLengths.append(length); previous = length
        }
        var budget = totalDuration - rests.reduce(0, +)
        for index in 0..<stageCount {
            let minimum = mode == .normal ? 120 : closingLengths[index] * 2 + 20
            let futureMin = ((index + 1)..<stageCount).reduce(0) { $0 + (mode == .normal ? 120 : closingLengths[$1] * 2 + 20) }
            let low = max(minimum, budget - (stageCount - index - 1) * 240)
            let high = min(240, budget - futureMin)
            let duration = draw(low...high)
            stageLengths.append(duration); budget -= duration
        }
        if Set(stageLengths).count == 1 {
            stageLengths[0] += 5; stageLengths[stageCount - 1] -= 5
        }
        if bleepyEnabled { scheduleBleep() }; beginStage()
    }
    mutating func stop() { self = ManualStageProgram() }
    private mutating func draw(_ range: ClosedRange<Int>) -> Int { Int.random(in: range, using: &rng) }
    private mutating func scheduleBleep() {
        nextBleep = elapsed + Double(draw(60...300))
    }

    mutating func advance(by seconds: Double) {
        guard active, seconds.isFinite, seconds > 0 else { return }
        let target = elapsed + seconds
        while elapsed < target {
            let boundary: Double
            switch phase {
            case .idle, .finished: return
            case .rest: boundary = overrideSegment ? min(restEnd, beatEnd) : restEnd
            case .stage: boundary = min(stageEnd, beatEnd)
            }
            let next = min(target, boundary, nextBleep, wheelSettlesAt)
            let delta = max(0, next - elapsed)
            if phase == .stage || overrideSegment {
                activeTime += delta
                if level == .ultrafast { ultraTime += delta }
                if phase == .stage {
                    stageActiveTime += delta
                    if level == .slow || level == .superSlow { stageSlowTime += delta }
                }
            }
            elapsed = next
            if elapsed >= nextBleep {
                bleepCount += 1
                pendingBleepy = BleepyEffect.allCases[draw(0...(BleepyEffect.allCases.count - 1))]
                selectedBleepy = nil; wheelStarted = elapsed
                wheelSettlesAt = elapsed + Self.wheelDuration
                lastBleep = "Bleepy: spinning…"; lastBleepAt = elapsed
                scheduleBleep()
            }
            if elapsed >= wheelSettlesAt, let effect = pendingBleepy {
                pendingBleepy = nil; selectedBleepy = effect; wheelSettlesAt = .infinity; resolvedBleepCount += 1
                applyBleepy(effect)
            }
            if phase == .stage && elapsed >= stageEnd { finishStage() }
            else if phase == .rest && elapsed >= restEnd { beginStage() }
            else if elapsed >= beatEnd && overrideSegment {
                overrideSegment = false
                if phase == .stage { chooseBeat() } else { level = .stop }
            }
            else if phase == .stage && elapsed >= beatEnd { chooseBeat() }
        }
    }

    mutating func applyBleepy(_ effect: BleepyEffect) {
        guard active else { return }
        lastBleepAt = elapsed
        switch effect {
        case .decrease, .increase, .increase10, .increase20, .decrease10, .decrease20, .decrease40, .randomIncrease:
            let delta = effect == .randomIncrease ? draw(10...40) : effect.adjustment!
            if phase == .stage {
                stageEnd = max(elapsed, stageEnd + Double(delta))
                if closing && !overrideSegment {
                    beatEnd = stageEnd
                    segmentDuration = max(1, segmentDuration + delta)
                }
                syncDuration()
                if elapsed >= stageEnd { finishStage() }
            } else {
                restEnd = max(elapsed, restEnd + Double(delta)); syncDuration()
                if elapsed >= restEnd { beginStage() }
            }
            lastBleep = "Bleepy: \(delta >= 0 ? "+" : "")\(delta)s"
        case .complete:
            if phase == .stage {
                stageEnd = elapsed; syncDuration(); finishStage()
            } else {
                restEnd = elapsed; syncDuration(); beginStage()
            }
            lastBleep = "Bleepy: stage complete"
        case .superSlow:
            beginOverride(.superSlow, duration: 30)
            lastBleep = "Bleepy: Super slow 30s"
        case .ultrafast:
            let duration = draw(15...30)
            beginOverride(.ultrafast, duration: duration)
            lastBleep = "Bleepy: Ultrafast \(duration)s"
        }
    }

    /// Bleepy deliberately ignores ordinary duration, proportion and closing-segment rules.
    private mutating func beginOverride(_ level: RhythmLevel, duration: Int) {
        overrideSegment = true; closing = false
        self.level = level; segmentDuration = duration; segment += 1
        beatEnd = elapsed + Double(duration)
        if phase == .stage { stageEnd = max(stageEnd, beatEnd) }
        else { restEnd = max(restEnd, beatEnd) }
        syncDuration()
    }

    private mutating func syncDuration() {
        if phase == .stage {
            stageDuration = max(0, Int(ceil(stageEnd - stageStart)))
            stageLengths[stage - 1] = stageDuration
        } else if phase == .rest {
            breakDuration = max(0, Int(ceil(restEnd - restStart)))
            rests[stage - 1] = breakDuration
        }
        totalDuration = stageLengths.reduce(0, +) + rests.reduce(0, +)
    }

    private mutating func beginStage() {
        stage += 1; segment = 0; stageActiveTime = 0; stageSlowTime = 0; level = .stop; closing = false; overrideSegment = false
        stageStart = elapsed; stageDuration = stageLengths[stage - 1]
        phase = .stage; stageEnd = elapsed + Double(stageDuration)
        chooseBeat()
    }

    private mutating func finishStage() {
        lastStageSlowFraction = stageActiveTime > 0 ? stageSlowTime / stageActiveTime : 0
        level = .stop; closing = false; overrideSegment = false
        if stage == stageCount { phase = .finished; pendingBleepy = nil; wheelSettlesAt = .infinity; return }
        phase = .rest; restStart = elapsed; breakDuration = rests[stage - 1]; restEnd = elapsed + Double(breakDuration)
    }

    private mutating func chooseBeat() {
        let tail = closingLengths[stage - 1]
        let remaining = max(0, Int((stageEnd - Double(tail) - elapsed).rounded()))
        if remaining == 0 {
            closing = true; level = .ultrafast; segmentDuration = max(1, Int((stageEnd - elapsed).rounded())); segment += 1; beatEnd = stageEnd
            return
        }
        // Bleepy time reductions may intentionally shorten the last segment.
        let valid = (min(10, remaining)...min(30, remaining)).filter {
            remaining == $0 || remaining - $0 >= 10
        }
        let duration = style == .consistent ? valid.min(by: { abs($0 - 20) < abs($1 - 20) })! : valid[draw(0...(valid.count - 1))]
        let previous = level
        // Ordinary choices use available budgets; Bleepy is explicitly exempt.
        let slowBudget = max(0, (stageActiveTime - 5 * stageSlowTime) / 4)
        let ultraBudget = max(0, activeTime - 2 * ultraTime)
        do {
            var others: [RhythmLevel] = [.normal, .fast]
            if style == .varied, segment > 0, previous != .ultrafast,
               remaining - duration >= 10, Double(duration + tail) <= ultraBudget + 1e-8 { others.append(.ultrafast) }
            others.removeAll { $0 == previous }
            let slowEligible = previous != .slow && Double(duration) <= slowBudget + 1e-8
            if style == .consistent {
                if slowEligible && segment % 5 == 4 { level = .slow }
                else { level = previous == .normal ? .fast : .normal }
            } else if slowEligible && Double.random(in: 0..<1, using: &rng) < slowChance { level = .slow }
            else { level = others[draw(0...(others.count - 1))] }
            segmentDuration = duration
        }
        segment += 1
        beatEnd = elapsed + Double(segmentDuration)
    }
}

/// Sector centers land exactly beneath the fixed top pointer after the spin.
enum BleepyWheelMath {
    static func rotation(progress: Double, effect: BleepyEffect) -> Double {
        let progress = progress.isFinite ? min(1, max(0, progress)) : 0
        let index = BleepyEffect.allCases.firstIndex(of: effect)!
        let final = 360 * 5 - Double(index) * 360 / Double(BleepyEffect.allCases.count)
        return final * (1 - pow(1 - progress, 3))
    }
}
