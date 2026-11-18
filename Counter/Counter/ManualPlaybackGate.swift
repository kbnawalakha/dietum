import Foundation

/// Video playback, not audio loudness or the beat-click toggle, controls the manual clock.
struct ManualPlaybackGate {
    private(set) var playing = false
    private var lastEvidence = -Double.infinity
    mutating func update(playing: Bool, now: Double) { self.playing = playing; lastEvidence = now }
    mutating func expire(at now: Double) { if now - lastEvidence > 0.75 { playing = false } }
    mutating func reset() { self = ManualPlaybackGate() }
}
