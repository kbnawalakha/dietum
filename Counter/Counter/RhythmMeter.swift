import Foundation

enum RhythmLevel: String, CaseIterable, Sendable {
    case stop = "Stop", slow = "Slow", normal = "Normal", fast = "Fast", ultrafast = "Ultrafast"
    var targetBPM: Double {
        switch self {
        case .stop: return 0
        case .slow: return 40
        case .normal: return 80
        case .fast: return 120
        case .ultrafast: return 180
        }
    }
}

struct RhythmSection: Sendable {
    let start: Double
    let end: Double
    let level: RhythmLevel
    var bpm: Double {
        guard level != .stop else { return 0 }
        // Fit whole cycles into the section, so each beat completes up AND down.
        let cycles = max(1, (Double(end - start) * level.targetBPM / 60).rounded())
        return cycles * 60 / (end - start)
    }
    func barPosition(at time: Double) -> Double {
        guard bpm > 0, time >= start, time < end else { return 0 }
        let phase = ((time - start) * bpm / 60).truncatingRemainder(dividingBy: 1)
        return 1 - abs(2 * phase - 1)
    }
}

enum RhythmMeter {
    static let minimumSection = 11.0

    static func sections(for timeline: RhythmTimeline) -> [RhythmSection] {
        guard timeline.duration > 10, timeline.duration.isFinite else { return [] }
        let count = max(1, Int(timeline.duration / minimumSection))
        let width = timeline.duration / Double(count)
        struct Window { let start: Double; let end: Double; let motion: Double; let audio: Double; let active: Bool }
        let windows: [Window] = (0..<count).map { index in
            let start = Double(index) * width
            let end = index == count - 1 ? timeline.duration : Double(index + 1) * width
            let movement = timeline.movement.filter { $0.time >= start && $0.time < end }
            let energy = movement.isEmpty ? 0 : movement.reduce(0) { $0 + $1.strength } / Double(movement.count)
            let motionCount = timeline.motion.filter { $0 >= start && $0 < end }.count
            let audioCount = timeline.audio.filter { $0 >= start && $0 < end }.count
            let active = movement.isEmpty ? motionCount >= 2 : energy >= 0.003
            return Window(start: start, end: end, motion: Double(motionCount) / width + energy * 4,
                          audio: Double(audioCount) / width, active: active)
        }
        let active = windows.filter(\.active)
        let maxMotion = active.map(\.motion).max() ?? 0
        let maxAudio = active.map(\.audio).max() ?? 0
        func score(_ window: Window) -> Double {
            // Audio can refine a moving section; it cannot turn a static video into movement.
            let motion = maxMotion > 0 ? window.motion / maxMotion : 0
            let audio = maxAudio > 0 ? window.audio / maxAudio : 0
            return 0.85 * motion + 0.15 * audio
        }
        let scores = active.map(score).sorted()
        func level(_ window: Window) -> RhythmLevel {
            guard window.active else { return .stop }
            // No meaningful variation across the full video: retain one Normal level.
            guard let first = scores.first, let last = scores.last, last - first > 0.12 else { return .normal }
            let value = score(window)
            let fraction = (value - first) / (last - first)
            if fraction < 0.25 { return .slow }
            if fraction < 0.5 { return .normal }
            if fraction < 0.75 { return .fast }
            return .ultrafast
        }
        var result: [RhythmSection] = []
        for window in windows {
            let value = level(window)
            if let previous = result.last, previous.level == value {
                result[result.count - 1] = RhythmSection(start: previous.start, end: window.end, level: value)
            } else {
                result.append(RhythmSection(start: window.start, end: window.end, level: value))
            }
        }
        return result
    }
}
