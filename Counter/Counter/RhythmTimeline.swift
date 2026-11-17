import Foundation

struct RhythmSample: Sendable {
    let time: Double
    let strength: Double
}

enum RhythmSource: String, CaseIterable, Sendable {
    case audio = "Audio", motion = "Movement", combined = "Both"
}

struct RhythmTimeline: Sendable {
    let audio: [Double]
    let motion: [Double]
    let duration: Double
    let movement: [RhythmSample]

    init(audio: [Double], motion: [Double], duration: Double, movement: [RhythmSample] = []) {
        self.audio = audio; self.motion = motion; self.duration = duration; self.movement = movement
    }

    func cues(for source: RhythmSource) -> [Double] {
        switch source {
        case .audio: return audio
        case .motion: return motion
        case .combined:
            return (audio + motion).sorted().reduce(into: []) { result, time in
                if time - (result.last ?? -1) >= 0.15 { result.append(time) }
            }
        }
    }

    // Local energy peaks, not semantic action recognition. No fabricated beats in gaps.
    static func peaks(_ samples: [RhythmSample], floor: Double, minimumGap: Double) -> [Double] {
        guard samples.count > 4 else { return [] }
        var result: [Double] = []
        for i in 1..<(samples.count - 1) {
            let sample = samples[i]
            guard sample.strength > floor,
                  sample.strength > samples[i - 1].strength,
                  sample.strength >= samples[i + 1].strength else { continue }
            let neighbors = samples[max(0, i - 12)...min(samples.count - 1, i + 12)]
            let baseline = neighbors.reduce(0) { $0 + $1.strength } / Double(neighbors.count)
            guard sample.strength > baseline * 1.35,
                  sample.time - (result.last ?? -10) >= minimumGap else { continue }
            result.append(sample.time)
        }
        return result
    }

    static func estimatedBPM(in cues: [Double], at time: Double) -> Int? {
        let recent = cues.filter { $0 <= time && $0 >= time - 4 }.suffix(5)
        guard recent.count >= 2, let last = recent.last, time - last < 2 else { return nil }
        let gaps = zip(recent, recent.dropFirst()).map { $1 - $0 }.filter { (0.25...2).contains($0) }.sorted()
        guard !gaps.isEmpty else { return nil }
        return Int((60 / gaps[gaps.count / 2]).rounded())
    }

    static func currentCue(in cues: [Double], at time: Double, playing: Bool) -> Int? {
        guard playing, time.isFinite else { return nil }
        // Binary search makes repeated playback updates inexpensive on longer videos.
        var low = 0
        var high = cues.count
        while low < high {
            let mid = (low + high) / 2
            if cues[mid] <= time { low = mid + 1 } else { high = mid }
        }
        guard low > 0, time - cues[low - 1] < 0.13 else { return nil }
        return low - 1
    }
}
