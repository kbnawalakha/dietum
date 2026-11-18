import Foundation

@main
struct StageChecks {
    static func main() {
        for seed in 0..<200 {
            var program = ManualStageProgram()
            program.start(mode: seed % 2 == 0 ? .normal : .random, seed: UInt64(seed), bleepyEnabled: false)
            precondition((5...6).contains(program.stageCount))
            precondition((900...1200).contains(program.totalDuration))
            precondition(Set(program.stageLengths).count > 1)
            precondition((10...15).contains(program.closingLengths[0]))
            precondition((27...30).contains(program.closingLengths.last!))
            precondition(zip(program.closingLengths, program.closingLengths.dropFirst()).allSatisfy { $0 <= $1 })
            var closed = 0
            for _ in 0..<5000 where program.active {
                let phase = program.phase, stage = program.stage, segment = program.segment, level = program.level
                let closing = program.closing
                program.advance(by: 0.5)
                precondition(program.stageSlowTime <= program.stageActiveTime * 0.2 + 1e-7)
                precondition(program.ultraTime <= program.activeTime * 0.5 + 1e-7)
                precondition((900...1200).contains(program.totalDuration))
                if phase == .stage && program.phase != .stage {
                    precondition(closing && level == .ultrafast, "Every stage must finish with Ultra")
                    closed += 1
                }
                if program.phase == .stage {
                    precondition((10...30).contains(program.segmentDuration), "seed \(seed) duration \(program.segmentDuration) stage \(program.stage) remaining \(program.remaining)")
                    if program.segment == 1 { precondition(program.level != .ultrafast) }
                }
                if phase == .stage && program.phase == .stage && stage == program.stage && segment != program.segment {
                    precondition(level != program.level)
                }
            }
            precondition(program.phase == .finished)
            precondition(program.stage == program.stageCount && closed == program.stageCount)
            precondition((900.0...1200.0).contains(program.elapsed))
            precondition(abs(program.elapsed - Double(program.totalDuration)) < 0.01)
            precondition(abs(program.slowChance - 0.2) < 1e-7)
        }
        precondition(BleepyEffect.allCases.count == 11)
        let edits: [(BleepyEffect, Int)] = [(.decrease,-30),(.increase,30),(.increase10,10),(.increase20,20),(.decrease10,-10),(.decrease20,-20),(.decrease40,-40)]
        for (effect, delta) in edits {
            var program = ManualStageProgram()
            program.start(mode: .normal, seed: 42, bleepyEnabled: false)
            let before = program.remaining
            program.applyBleepy(effect)
            precondition(program.remaining == before + Double(delta), "Time edit must not be cap-clamped")
        }
        var randomAdds = Set<Int>()
        for seed in 0..<100 {
            var program = ManualStageProgram()
            program.start(mode: .normal, seed: UInt64(seed), bleepyEnabled: false)
            let before = program.remaining
            program.applyBleepy(.randomIncrease)
            let delta = Int(program.remaining - before)
            precondition((10...40).contains(delta)); randomAdds.insert(delta)
        }
        precondition(randomAdds.count > 20 && randomAdds.max()! > 30)
        var slow = ManualStageProgram()
        slow.start(mode: .normal, seed: 42, bleepyEnabled: false)
        slow.applyBleepy(.superSlow)
        precondition(slow.level == .superSlow && slow.segmentDuration == 30 && slow.overrideSegment)
        precondition(RhythmLevel.superSlow.targetBPM < RhythmLevel.slow.targetBPM)
        slow.advance(by: 30)
        precondition(slow.stageSlowTime == 30 && slow.stageActiveTime == 30, "Super Slow bypasses normal cap")
        var ultra = ManualStageProgram()
        ultra.start(mode: .normal, seed: 42, bleepyEnabled: false)
        ultra.applyBleepy(.ultrafast)
        precondition(ultra.level == .ultrafast && (15...30).contains(ultra.segmentDuration))
        ultra.advance(by: Double(ultra.segmentDuration))
        precondition(ultra.ultraTime == ultra.activeTime, "Bleepy Ultra bypasses normal cap")
        var long = ManualStageProgram()
        long.start(mode: .normal, seed: 42, bleepyEnabled: false)
        let originalTotal = long.totalDuration
        for _ in 0..<40 { long.applyBleepy(.increase10) }
        precondition(long.totalDuration == originalTotal + 400 && long.totalDuration > 1200)
        long.applyBleepy(.complete)
        precondition(long.phase == .rest, "Stage completion must be immediate")
        long.applyBleepy(.superSlow)
        precondition(long.phase == .rest && long.overrideSegment && long.level == .superSlow)
        var closing = ManualStageProgram()
        closing.start(mode: .normal, seed: 42, bleepyEnabled: false)
        while !closing.closing { closing.advance(by: 0.5) }
        let beforeClosing = closing.remaining
        closing.applyBleepy(.increase20)
        precondition(closing.remaining == beforeClosing + 20)
        closing.applyBleepy(.superSlow)
        precondition(closing.level == .superSlow && !closing.closing)
        for seed in 0..<200 {
            var program = ManualStageProgram()
            program.start(mode: .normal, seed: UInt64(seed))
            for tick in 0..<10000 where program.active {
                program.advance(by: 0.5)
                if tick % 311 == 0 { program.applyBleepy(BleepyEffect.allCases[(tick / 311) % BleepyEffect.allCases.count]) }
                precondition(program.remaining >= 0)
            }
            precondition(program.phase == .finished, "Override fuzz programs must terminate")
        }
        print("11 Bleepy outcomes passed: exact edits, random 10–40s, immediate 30s Super Slow/Ultra, cap bypass, closing/break overrides, 200 randomized programs")
        var intervals = Set<Int>()
        var sawBreakSpin = false, sawMidBeatSpin = false
        for seed in 0..<200 {
            var program = ManualStageProgram()
            program.start(mode: .normal, seed: UInt64(seed))
            precondition((60...300).contains(Int(program.nextBleep)))
            var previousStart = 0.0
            for _ in 0..<30 where program.active {
                let wait = program.nextBleep - program.elapsed
                let interval = program.nextBleep - previousStart
                precondition((60.0...300.0).contains(interval))
                intervals.insert(Int(interval))
                program.advance(by: wait)
                guard program.active else { break }
                precondition(program.spinning && program.selectedBleepy == nil)
                previousStart = program.wheelStarted
                sawBreakSpin = sawBreakSpin || program.phase == .rest
                sawMidBeatSpin = sawMidBeatSpin || (program.phase == .stage && program.segmentRemaining > 1 && program.segmentRemaining < Double(program.segmentDuration) - 1)
                let pending = program.pendingBleepy
                let resolved = program.resolvedBleepCount
                program.advance(by: ManualStageProgram.wheelDuration - 0.5)
                guard program.active else { break }
                precondition(program.spinning && program.resolvedBleepCount == resolved)
                program.advance(by: 0.5)
                precondition(!program.spinning && program.selectedBleepy == pending)
                precondition(program.resolvedBleepCount == resolved + 1)
            }
        }
        precondition(intervals.count > 100 && intervals.min()! >= 60 && intervals.max()! <= 300)
        precondition(sawBreakSpin && sawMidBeatSpin)
        for (index, effect) in BleepyEffect.allCases.enumerated() {
            precondition(BleepyWheelMath.reelPosition(progress: 0, effect: effect) == Double(BleepyEffect.allCases.count))
            let final = BleepyWheelMath.reelPosition(progress: 1, effect: effect)
            let aligned = final.truncatingRemainder(dividingBy: Double(BleepyEffect.allCases.count))
            precondition(abs(aligned - Double(index)) < 1e-6, "Reel must stop on the applied outcome")
            precondition(final - Double(BleepyEffect.allCases.count) >= Double(BleepyEffect.allCases.count * 2))
            precondition(BleepyWheelMath.reelPosition(progress: 0.3, effect: effect) < BleepyWheelMath.reelPosition(progress: 0.6, effect: effect))
        }
        var cancelled = ManualStageProgram()
        cancelled.start(mode: .normal, seed: 42)
        cancelled.advance(by: cancelled.nextBleep)
        precondition(cancelled.spinning)
        cancelled.stop(); cancelled.advance(by: 10)
        precondition(!cancelled.spinning && !cancelled.wheelVisible && cancelled.resolvedBleepCount == 0)
        print("Bleepy wheel checks passed: 60–300s gaps, mid-beat/break triggers, delayed reveal/application, all pointer targets, cancellation")
        var hiddenCount = 0, visibleCount = 0, delays = Set<Int>()
        for seed in 0..<200 {
            var program = ManualStageProgram()
            program.start(mode: .normal, seed: UInt64(seed), bleepyEnabled: false)
            if program.stageCountdownDelay == 0 {
                visibleCount += 1; precondition(program.stageCountdownVisible)
            } else {
                hiddenCount += 1
                let delay = program.stageCountdownDelay
                delays.insert(Int(delay)); precondition((30.0...60.0).contains(delay))
                precondition(!program.stageCountdownVisible)
                program.advance(by: delay - 0.5)
                precondition(!program.stageCountdownVisible)
                // No clock advancement during pause means no premature reveal.
                precondition(!program.stageCountdownVisible)
                program.advance(by: 0.5)
                precondition(program.stageCountdownVisible)
            }
            let oldStage = program.stage
            while program.stage == oldStage { program.advance(by: 0.5) }
            precondition(program.stageCountdownVisible == (program.stageCountdownDelay == 0))
            program.stop(); precondition(!program.stageCountdownVisible)
        }
        precondition(hiddenCount > 60 && visibleCount > 60 && delays.count > 20)
        print("Countdown reveal checks passed: mixed visible/hidden stages, 30–60s delays, exact reveal, pause/reset, no pacing RNG changes")
        var gate = ManualPlaybackGate()
        precondition(!gate.playing)
        gate.update(playing: true, now: 0)
        precondition(gate.playing)
        gate.update(playing: false, now: 0.1)
        precondition(!gate.playing)
        gate.update(playing: true, now: 1)
        gate.expire(at: 1.5)
        precondition(gate.playing)
        gate.expire(at: 2)
        precondition(!gate.playing)
        print("Playback gate checks passed: playing, pause, stale player evidence")
        print("Bounded program checks passed: 200 seeds, randomized stages, 15–20 minutes, 5–6 stages, non-Ultra starts, progressive Ultra endings, normal caps without Bleepy overrides")
    }
}
