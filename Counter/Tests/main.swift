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
// Constant motion without rhythmic peaks must NOT turn into a preset metronome.
var constant = LiveRhythmMeter()
for frame in 0...240 {
    let time = Double(frame) / 12
    constant.advance(to: time)
    constant.ingest(LiveRhythmSample(time: time, movement: 0.02, audio: frame % 6 == 0 ? 0.8 : 0))
}
assert(constant.ready && !constant.tracking && constant.position == 0 && constant.measuredBPM == nil)

func observedMeter(cycleFrames: Int) -> LiveRhythmMeter {
    var meter = LiveRhythmMeter()
    for frame in 0...240 {
        let time = Double(frame) / 12
        meter.advance(to: time)
        meter.ingest(LiveRhythmSample(time: time, movement: frame % cycleFrames == 2 ? 0.12 : 0.001,
                                      audio: frame % 3 == 0 ? 0.8 : 0.001))
    }
    return meter
}
let slower = observedMeter(cycleFrames: 10) // observed 72 BPM, not a preset
let faster = observedMeter(cycleFrames: 8)  // observed 90 BPM, same named level
assert(slower.tracking && faster.tracking)
assert(abs(slower.measuredBPM! - 72) < 0.001)
assert(abs(faster.measuredBPM! - 90) < 0.001)
assert(slower.level == faster.level)
// At t=20, most recent confirmed video peaks are 232/12 and 234/12.
let slowPhase = (20 - 232.0 / 12) / (10.0 / 12)
let fastPhase = (20 - 234.0 / 12) / (8.0 / 12)
assert(abs(slower.position - (1 - abs(2 * slowPhase - 1))) < 0.00001)
assert(abs(faster.position - (1 - abs(2 * fastPhase - 1))) < 0.00001)
var missing = slower
for frame in 241...264 { missing.advance(to: Double(frame) / 12) }
assert(!missing.tracking && missing.position == 0 && missing.measuredBPM == nil)
// A full observed 90 BPM cycle rises and falls, with its phase referenced to the video peak.
var cycle = faster
cycle.advance(to: 20.05)
assert(cycle.position < faster.position)
cycle.advance(to: 20.2)
assert(cycle.position == 0) // completes and waits; no invented second cycle
print("Video-derived 72/90 BPM and phase, audio independence, missing-motion stop, and complete-cycle checks passed")

func webEvent(_ kind: String = "frame", id: String = "player", time: Double = 0, area: Double = 10000,
              value: Double = 0.1) -> EmbeddedVideoEvent {
    EmbeddedVideoEvent(body: ["kind": kind, "id": id, "time": time, "area": area,
                               "grid": Array(repeating: value, count: 256)])!
}
assert(EmbeddedVideoEvent(body: ["kind": "frame", "id": "x", "time": 0.0, "area": 1.0, "grid": [0.5]]) == nil)
assert(EmbeddedVideoEvent(body: ["kind": "frame", "id": "x", "time": Double.nan, "area": 1.0]) == nil)
assert(EmbeddedVideoEvent(body: ["kind": "unknown"]) == nil)
assert(EmbeddedVideoEvent(body: ["kind": "frame", "id": "x", "time": 0.0, "area": 1.0,
                               "grid": Array(repeating: 2.0, count: 256)]) == nil)
var router = EmbeddedMotionRouter()
assert(router.receive(webEvent(), now: 0)?.sample?.movement == 0)
assert(router.receive(webEvent(time: 0.1, value: 0.2), now: 0.1)!.sample!.movement > 0.09)
assert(router.receive(webEvent(time: 0.1), now: 0.11) == nil) // duplicate browser frame
assert(router.receive(webEvent(id: "small-ad", time: 0.2, area: 100), now: 0.2) == nil)
assert(router.receive(EmbeddedVideoEvent(body: ["kind": "idle"])!, now: 0.3) == nil)
assert(router.receive(webEvent("paused", time: 0.1), now: 0.4)?.kind == .paused)
assert(router.receive(webEvent(id: "new-playing", time: 0.5, area: 100), now: 0.5)?.reset == true)
assert(router.receive(webEvent("paused", time: 0.1), now: 0.6) == nil)
assert(router.receive(webEvent(id: "new-playing", time: 10, area: 100), now: 0.7)?.reset == true)
assert(router.receive(webEvent("blocked", id: "new-playing", time: 10, area: 100), now: 0.8)?.reset == true)
assert(router.receive(EmbeddedVideoEvent(body: ["kind": "idle"])!, now: 4)?.kind == .idle)
// Embedded numeric frames drive the same observed cadence without native playback or saved media.
router.reset()
var embeddedMeter = LiveRhythmMeter()
for index in 0..<240 {
    let time = Double(index) / 12
    let value = (index / 5) % 2 == 0 ? 0.1 : 0.3
    let update = router.receive(webEvent(time: time, value: value), now: time)!
    if update.reset { embeddedMeter.reset() }
    if let sample = update.sample { embeddedMeter.advance(to: time); embeddedMeter.ingest(sample) }
}
assert(embeddedMeter.ready)
assert(embeddedMeter.samples.count <= 64)
assert(embeddedMeter.measuredBPM != nil && abs(embeddedMeter.measuredBPM! - 144) < 0.001)
print("Embedded bridge checks passed: validation, duplicate/iframe filtering, pause, player switch, seek, blocked access, bounded motion-derived cadence")
