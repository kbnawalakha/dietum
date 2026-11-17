import Foundation

let resolver = LinkResolver()
func resolved(_ input: String) -> URL { try! resolver.resolve(input) }
func expectInvalid(_ value: String) {
    do { _ = try resolver.resolve(value); fatalError("Accepted invalid input") }
    catch is LinkError { }
    catch { fatalError("Unexpected error") }
}
for input in ["", "   ", "javascript:alert(1)", "file:///tmp/movie.mp4", "ftp://example.com/a", "https://", "https://user:secret@example.com/a", "not a link"] {
    expectInvalid(input)
}
assert(resolved(" example.com/watch?v=123 \n").absoluteString == "https://example.com/watch?v=123")
assert(resolved("http://example.com/movie.mp4").scheme == "http")
assert(resolver.isDirectVideo(resolved("https://example.com/VIDEO.MP4?token=123")))
assert(resolver.isDirectVideo(resolved("https://example.com/live.m3u8")))
assert(!resolver.isDirectVideo(resolved("https://example.com/watch?v=movie.mp4")))
print("13 link validation and routing checks passed")

let silence = (0..<300).map { RhythmSample(time: Double($0) * 0.02, strength: 0) }
assert(RhythmTimeline.peaks(silence, floor: 0.015, minimumGap: 0.25).isEmpty)
let steady = (0..<300).map { RhythmSample(time: Double($0) * 0.02, strength: 0.1) }
assert(RhythmTimeline.peaks(steady, floor: 0.015, minimumGap: 0.25).isEmpty)
// 120 BPM impulses, with a silent gap. Do not invent beats in that gap.
let impulses = (0..<300).map { index in
    RhythmSample(time: Double(index) * 0.02, strength: index % 25 == 10 && !(100..<200).contains(index) ? 0.7 : 0.001)
}
let detected = RhythmTimeline.peaks(impulses, floor: 0.015, minimumGap: 0.25)
assert(detected.count == 8)
assert(!detected.contains(where: { (2..<4).contains($0) }))
assert(abs(detected[1] - detected[0] - 0.5) < 0.001)
let timeline = RhythmTimeline(audio: [0.5, 1, 2], motion: [0.55, 1.5, 2.05], duration: 3)
assert(timeline.cues(for: .combined) == [0.5, 1, 1.5, 2])
assert(timeline.cues(for: .audio) == [0.5, 1, 2])
assert(timeline.cues(for: .motion) == [0.55, 1.5, 2.05])
let cues = timeline.cues(for: .combined)
assert(RhythmTimeline.currentCue(in: cues, at: 0.51, playing: true) == 0)
assert(RhythmTimeline.currentCue(in: cues, at: 0.51, playing: false) == nil)
assert(RhythmTimeline.currentCue(in: cues, at: 0.9, playing: true) == nil)
assert(RhythmTimeline.currentCue(in: cues, at: 2.01, playing: true) == 3)
assert(RhythmTimeline.currentCue(in: cues, at: 0.51, playing: true) == 0) // backwards seek
assert(RhythmTimeline.currentCue(in: cues, at: .nan, playing: true) == nil)
assert(RhythmTimeline.currentCue(in: [], at: 1, playing: true) == nil)
assert(RhythmTimeline.estimatedBPM(in: [0.5, 1, 1.5, 2], at: 2.1) == 120)
assert(RhythmTimeline.estimatedBPM(in: [0.5, 1, 1.5, 2], at: 5) == nil)
assert(RhythmTimeline.estimatedBPM(in: [], at: 1) == nil)
print("18 rhythm signal, tempo and playback-position checks passed")

var live = LiveRhythmMeter()
var changes: [(time: Double, level: RhythmLevel)] = []
for frame in 0..<900 {
    let time = Double(frame) / 12
    live.advance(to: time)
    // Silence/static, then movement, then static; audio stays loud throughout.
    let strength = time >= 16 && time < 48 ? 0.04 : 0.0
    live.ingest(LiveRhythmSample(time: time, movement: strength, audio: frame % 6 == 0 ? 0.8 : 0.001))
    if live.ready && changes.last?.level != live.level { changes.append((time, live.level)) }
    assert(live.samples.count <= 64)
}
assert(changes.first?.level == .stop && changes.last?.level == .stop)
assert(changes.contains { $0.level == .fast })
assert(zip(changes, changes.dropFirst()).allSatisfy { $1.time - $0.time > 10 })
assert(live.samples.first!.time >= live.samples.last!.time - 4.01)
let beforePause = live.position
// No time advancement during a pause means no synthetic ticking.
assert(live.position == beforePause)
live.advance(to: 5) // backwards seek
assert(!live.ready && live.samples.isEmpty)
live.advance(to: 30) // forwards seek
assert(!live.ready)
for (strength, expected) in [(0.0, RhythmLevel.stop), (0.006, .slow), (0.02, .normal), (0.05, .fast), (0.1, .ultrafast)] {
    let window = (0..<48).map { LiveRhythmSample(time: Double($0) / 12, movement: strength, audio: nil) }
    assert(LiveRhythmMeter.classify(window) == expected)
}
var cycle = LiveRhythmMeter()
for frame in 0...48 {
    let time = Double(frame) / 12
    cycle.advance(to: time)
    cycle.ingest(LiveRhythmSample(time: time, movement: 0.02, audio: nil))
}
assert(cycle.ready && cycle.level == .normal)
let cycleStart = cycle.position
cycle.advance(to: 4.375) // half a Normal cycle at 80 BPM
assert(abs(cycle.position - (1 - cycleStart)) < 0.00001)
cycle.advance(to: 4.75)
assert(abs(cycle.position - cycleStart) < 0.00001)
print("Live levels, >10s holds, bounded memory, seeks, stationary audio rejection, and full-cycle checks passed")
