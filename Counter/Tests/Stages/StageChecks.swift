import Foundation

@main
struct StageChecks {
    static func main() {
        for seed in 0..<200 {
            var program = ManualStageProgram()
            program.start(mode: seed % 2 == 0 ? .normal : .random, seed: UInt64(seed), style: seed % 3 == 0 ? .consistent : .varied)
            precondition((5...6).contains(program.stageCount))
            precondition((900...1200).contains(program.totalDuration))
            precondition(Set(program.stageLengths).count > 1)
            precondition((10...15).contains(program.closingLengths[0]))
            precondition((27...30).contains(program.closingLengths.last!))
            precondition(zip(program.closingLengths, program.closingLengths.dropFirst()).allSatisfy { $0 <= $1 })
            var closed = 0
            for tick in 0..<5000 where program.active {
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
                    precondition((10...30).contains(program.segmentDuration), "seed \(seed) tick \(tick) duration \(program.segmentDuration) stage \(program.stage) remaining \(program.remaining)")
                    if program.segment == 1 { precondition(program.level != .ultrafast) }
                }
                if phase == .stage && program.phase == .stage && stage == program.stage && segment != program.segment {
                    precondition(level != program.level)
                }
                if tick % 311 == 0 { program.applyBleepy(BleepyEffect.allCases[(tick / 311) % 4]) }
            }
            precondition(program.phase == .finished)
            precondition(program.stage == program.stageCount && closed == program.stageCount)
            precondition((900.0...1200.0).contains(program.elapsed))
            precondition(abs(program.elapsed - Double(program.totalDuration)) < 0.01)
            precondition(abs(program.slowChance - 0.2) < 1e-7)
        }
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
        print("Bounded program checks passed: 200 seeds, both styles, 15–20 minutes, 5–6 stages, non-Ultra starts, progressive Ultra endings, caps and Bleepy edits")
    }
}
