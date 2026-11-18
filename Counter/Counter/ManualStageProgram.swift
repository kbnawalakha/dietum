import Foundation

enum StageDurationMode: String, CaseIterable { case normal = "Normal", random = "Random" }
enum ManualProgramStyle { case varied, consistent }
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

    var active: Bool { phase == .stage || phase == .rest }
    var sessionRemaining: Double { max(0, Double(totalDuration) - elapsed) }
    var remaining: Double { max(0, (phase == .rest ? restEnd : stageEnd) - elapsed) }
    var segmentRemaining: Double { phase == .stage ? max(0, min(beatEnd, stageEnd) - elapsed) : 0 }
    var slowChance: Double { max(0.2, 0.5 - 0.3 * Double(max(0, stage - 1)) / Double(max(1, stageCount - 1))) }
    var ultraFraction: Double { activeTime > 0 ? ultraTime / activeTime : 0 }

    mutating func start(mode: StageDurationMode, seed: UInt64, style: ManualProgramStyle = .varied) {
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
            case .idle, .finished: return
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
        let index = phase == .rest ? stage : stage - 1
        switch effect {
        case .decrease, .increase:
            guard index < stageCount else { return }
            let delta = effect == .decrease ? -30 : 30
            if closing { lastBleep = "Bleepy: closing Ultrafast protected"; return }
            resizeStage(index: index, desired: stageLengths[index] + delta)
            lastBleep = effect == .decrease ? "Bleepy: stage −30s (within limits)" : "Bleepy: stage +30s (within limits)"
        case .complete:
            if closing { lastBleep = "Bleepy: closing Ultrafast already running"; return }
            if phase == .stage {
                resizeStage(index: index, desired: minimumCurrentDuration())
            } else if index < stageCount {
                resizeStage(index: index, desired: closingLengths[index] * 2 + 20)
            }
            lastBleep = "Bleepy: finish after closing Ultrafast"
        case .ultrafast:
            if closing && stage == stageCount { lastBleep = "Bleepy: final Ultrafast already running"; return }
            forcedUltra = draw(15...30)
            lastBleep = "Bleepy: Ultrafast \(forcedUltra!)s queued"
        }
    }

    private func minimumCurrentDuration() -> Int {
        let tail = Double(closingLengths[stage - 1])
        let restOfBeat = max(0, beatEnd - elapsed)
        let fundsAfterBeat = activeTime - 2 * ultraTime + (level == .ultrafast ? -restOfBeat : restOfBeat)
        var extra = max(0, Int(ceil(tail - fundsAfterBeat)))
        if extra > 0 || level == .ultrafast { extra = max(10, extra) }
        return Int(ceil(beatEnd - stageStart)) + extra + Int(tail)
    }

    /// Redistribute time rather than silently violating the 15–20 minute program boundary.
    private mutating func resizeStage(index: Int, desired: Int) {
        let current = phase == .stage && index == stage - 1
        var target = max(current ? minimumCurrentDuration() : closingLengths[index] * 2 + 20, desired)
        if current {
            let afterBeat = Double(target) + stageStart - Double(closingLengths[index]) - beatEnd
            if afterBeat > 0 && afterBeat < 10 { target += Int(ceil(10 - afterBeat)) }
            if level == .ultrafast && afterBeat < 10 { target += Int(ceil(10 - afterBeat)) }
        }
        let wanted = target - stageLengths[index]
        let future = Array((index + 1)..<stageCount)
        let capacity = future.reduce(0) { total, i in
            total + (wanted > 0 ? max(0, stageLengths[i] - (closingLengths[i] * 2 + 20)) : max(0, 240 - stageLengths[i]))
        }
        let sessionSlack = wanted > 0 ? 1200 - totalDuration : totalDuration - 900
        var amount = min(abs(wanted), capacity + sessionSlack)
        if current {
            while amount > 0 {
                let candidate = stageLengths[index] + (wanted >= 0 ? amount : -amount)
                let gap = Double(candidate) + stageStart - Double(closingLengths[index]) - beatEnd
                if candidate >= minimumCurrentDuration(), gap >= 10 || (abs(gap) < 0.01 && level != .ultrafast) { break }
                amount -= 1
            }
        }
        let delta = wanted >= 0 ? amount : -amount
        stageLengths[index] += delta
        var remaining = amount
        for i in future {
            let room = wanted > 0 ? max(0, stageLengths[i] - (closingLengths[i] * 2 + 20)) : max(0, 240 - stageLengths[i])
            let use = min(room, remaining)
            stageLengths[i] += wanted > 0 ? -use : use
            remaining -= use
        }
        totalDuration = stageLengths.reduce(0, +) + rests.reduce(0, +)
        if current { stageDuration = stageLengths[index]; stageEnd = stageStart + Double(stageDuration) }
    }

    private mutating func beginStage() {
        stage += 1; segment = 0; stageActiveTime = 0; stageSlowTime = 0; level = .stop; closing = false
        stageStart = elapsed; stageDuration = stageLengths[stage - 1]
        phase = .stage; stageEnd = elapsed + Double(stageDuration)
        chooseBeat()
    }

    private mutating func finishStage() {
        lastStageSlowFraction = stageActiveTime > 0 ? stageSlowTime / stageActiveTime : 0
        level = .stop; closing = false
        if stage == stageCount { phase = .finished; forcedUltra = nil; return }
        phase = .rest; breakDuration = rests[stage - 1]; restEnd = elapsed + Double(breakDuration)
    }

    private mutating func chooseBeat() {
        let tail = closingLengths[stage - 1]
        let remaining = max(0, Int((stageEnd - Double(tail) - elapsed).rounded()))
        if remaining == 0 {
            closing = true; level = .ultrafast; segmentDuration = tail; segment += 1; beatEnd = stageEnd
            return
        }
        // Bleepy time reductions may intentionally shorten the last segment.
        let valid = (min(10, remaining)...min(30, remaining)).filter {
            remaining == $0 || remaining - $0 >= 10
        }
        let duration = style == .consistent ? valid.min(by: { abs($0 - 20) < abs($1 - 20) })! : valid[draw(0...(valid.count - 1))]
        let previous = level
        // Prefix budgets keep caps true even if Bleepy ends/shortens a stage unexpectedly.
        let slowBudget = max(0, (stageActiveTime - 5 * stageSlowTime) / 4)
        let ultraBudget = max(0, activeTime - 2 * ultraTime)
        if let forcedUltra, segment > 0, previous != .ultrafast, Double(forcedUltra + tail) <= ultraBudget + 1e-8,
           remaining - forcedUltra >= 10 {
            self.forcedUltra = nil
            level = .ultrafast; segmentDuration = forcedUltra
        } else {
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
