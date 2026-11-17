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
