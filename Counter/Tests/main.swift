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

// Whole-video movement levels with an audio-only first section: it must stay Stop.
let movement = (0..<550).map { index in
    RhythmSample(time: Double(index) / 10, strength: Double(index / 110) * 0.01)
}
var motionCues: [Double] = []
for level in 1...4 {
    for index in 0..<(level * 5) {
        let start = 11.0 * Double(level)
        let offset = Double(index) * 11.0 / Double(level * 5)
        motionCues.append(start + offset)
    }
}
let meterTimeline = RhythmTimeline(audio: stride(from: 0.0, to: 55, by: 0.3).map { $0 }, motion: motionCues, duration: 55, movement: movement)
let sections = RhythmMeter.sections(for: meterTimeline)
assert(sections.map(\.level) == [.stop, .slow, .normal, .fast, .ultrafast])
assert(sections.allSatisfy { $0.end - $0.start > 10 })
assert(sections.first?.start == 0 && sections.last?.end == 55)
assert(zip(sections, sections.dropFirst()).allSatisfy { $0.end == $1.start })
for section in sections where section.level != .stop {
    let period = 60 / section.bpm
    assert(abs(section.barPosition(at: section.start)) < 0.000001)
    assert(abs(section.barPosition(at: section.start + period / 2) - 1) < 0.000001)
    assert(abs(section.barPosition(at: section.start + period)) < 0.000001)
    let cycles = (section.end - section.start) / period
    assert(abs(cycles - cycles.rounded()) < 0.000001)
}
assert(sections[0].barPosition(at: 5) == 0)
let stopped = RhythmTimeline(audio: Array(stride(from: 0.0, to: 35.0, by: 0.25)), motion: [], duration: 35,
                             movement: (0..<350).map { RhythmSample(time: Double($0) / 10, strength: 0) })
assert(RhythmMeter.sections(for: stopped).map(\.level) == [.stop])
assert(RhythmMeter.sections(for: RhythmTimeline(audio: [], motion: [], duration: 10)).isEmpty)
let shortTail = RhythmMeter.sections(for: RhythmTimeline(audio: [], motion: [1,2,3,12,13,14], duration: 23))
assert(shortTail.allSatisfy { $0.end - $0.start > 10 })
assert(shortTail.last?.end == 23)
assert(zip(sections.dropFirst(), sections.dropFirst(2)).allSatisfy { $0.bpm < $1.bpm })
print("Whole-video levels, minimum holds, complete bar cycles, motion priority, and short-video checks passed")
