import Foundation

@main
struct StageChecks {
    static func main() {
        var sawZero = false
        for seed in 0..<100 {
            var normal = ManualStageProgram()
            normal.start(mode: .normal, seed: UInt64(seed))
            precondition((120...240).contains(normal.stageDuration))
            precondition((10...30).contains(normal.segmentDuration))
            var random = ManualStageProgram()
            random.start(mode: .random, seed: UInt64(seed))
            precondition((0...240).contains(random.stageDuration))
            if random.stageDuration == 0 {
                sawZero = true
                precondition(random.phase == .rest && (15...30).contains(random.breakDuration))
            }
        }
        precondition(sawZero)
        var slowObserved = false, ultraObserved = false, lowestChance = 1.0
        for seed in 0..<50 {
            var program = ManualStageProgram()
            program.start(mode: seed % 2 == 0 ? .normal : .random, seed: UInt64(seed))
            for _ in 0..<3600 {
                let oldStage = program.stage, oldSegment = program.segment, oldPhase = program.phase, oldLevel = program.level
                program.advance(by: 1)
                precondition(program.stageSlowTime <= program.stageActiveTime * 0.2 + 1e-7, "Slow cap must hold even before stage ends")
                precondition(program.ultraTime <= program.activeTime * 0.5 + 1e-7, "Ultrafast prefix cap")
                precondition(program.lastStageSlowFraction <= 0.2 + 1e-7)
                precondition(program.slowChance >= 0.2 && program.slowChance <= 0.5)
                lowestChance = min(lowestChance, program.slowChance)
                slowObserved = slowObserved || program.level == .slow
                ultraObserved = ultraObserved || program.level == .ultrafast
                if program.phase == .rest { precondition((15...30).contains(program.breakDuration)) }
                if oldPhase == .stage && program.phase == .stage && oldStage == program.stage && oldSegment != program.segment {
                    precondition(oldLevel != program.level, "Consecutive speed segments must differ")
                }
            }
            precondition(program.bleepCount == 12, "One random event in each five-minute block")
            precondition((3601...3899).contains(Int(program.nextBleep)))
        }
        precondition(slowObserved && ultraObserved && abs(lowestChance - 0.2) < 1e-7)
        // Find an initial block whose Bleepy occurs after the longest natural first stage.
        var quiet = ManualStageProgram()
        for seed in 0..<1000 {
            quiet.start(mode: .normal, seed: UInt64(seed))
            if quiet.nextBleep > 240 { break }
        }
        precondition(quiet.nextBleep > 240)
        let duration = quiet.remaining
        quiet.applyBleepy(.increase)
        precondition(quiet.remaining == duration + 30)
        quiet.applyBleepy(.decrease)
        precondition(quiet.remaining == duration)
        var forced = quiet
        forced.applyBleepy(.ultrafast)
        precondition((15...30).contains(forced.forcedUltra!))
        precondition(forced.level != .ultrafast, "An unfunded Ultra request must wait")
        var forcedStarted = false
        for _ in 0..<240 {
            forced.advance(by: 1)
            if forced.level == .ultrafast && forced.forcedUltra == nil { forcedStarted = true; break }
        }
        precondition(forcedStarted)
        quiet.applyBleepy(.complete)
        precondition(quiet.phase == .rest && quiet.level == .stop)
        let breakRemaining = quiet.remaining
        quiet.advance(by: breakRemaining)
        precondition(quiet.stage == 2)
        var shortened = forced
        shortened.applyBleepy(.complete)
        precondition(shortened.lastStageSlowFraction <= 0.2 + 1e-7)
        let stoppedElapsed = shortened.elapsed
        shortened.stop(); shortened.advance(by: 100)
        precondition(!shortened.active && shortened.elapsed == 0 && stoppedElapsed > 0)
        print("Manual stage checks passed: 100 duration seeds, 50 one-hour programs, Slow≤20% per stage, Ultra≤50%, changing speeds, breaks, all Bleepy outcomes, queueing and stop")
    }
}
