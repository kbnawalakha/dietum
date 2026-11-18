# Decision Log

## ADR-001 — Local-First Application

Decision:

Dietum will initially be a single-user local iPhone application.

Reason:

The initial product is for personal use and does not require authentication or synchronization.

Status:

Accepted.

## ADR-005 — Optional Google Drive Backup

Decision:

Keep Dietum local-first, but allow users to opt into Google sign-in and private weekly Drive backups. Skipping account setup must leave the local app fully usable.

Reason:

Users requested a recoverable weekly backup without changing the default privacy model or introducing Dietum accounts and cloud synchronization.

Status:

Accepted.

## ADR-002 — SwiftData Persistence

Decision:

Use SwiftData for structured local persistence.

Reason:

It integrates directly with SwiftUI and is sufficient for the current MVP.

Status:

Accepted.

## ADR-003 — Mock Meal Analysis First

Decision:

Build meal-photo analysis behind a protocol and begin with a deterministic mock service.

Reason:

This allows UI and data flows to be completed before selecting or paying for a production AI service.

Status:

Accepted.

## ADR-004 — User-Approved Calorie Changes

Decision:

Nutrition-target adjustments must be proposed to the user and cannot silently modify the active plan.

Reason:

Nutrition recommendations are estimates and must remain user-controlled.

Status:

Accepted.


## Counter ADR-001 — Streaming-Only Rhythm Analysis

Decision: Counter must not download or store a video for analysis. Observe decoded native-player frames and optional pass-through audio using bounded in-memory evidence. Remove the whole-file analyzer and future section plan; classify levels as playback progresses. Keep 11-second minimum holds and finish the current bar cycle before a level change during uninterrupted playback.

Reason: The user explicitly requires realtime analysis and streaming only. Unseen future footage cannot be classified under that constraint. Standard AVPlayer buffering is system-managed; Counter creates no media files, offline copies, saved links, or analysis history. A deletion-only migration cleanup removes media from the prior implementation.

Status: Accepted, specific to the separate Counter app; Dietum architecture is unchanged.

## Counter ADR-002 — Embedded Video Frame Adapter

Decision: allow best-effort streaming movement analysis for HTML video elements in WebKit pages/iframes using an isolated-world user script packaged inside Swift. The small DOM/canvas adapter is required because native Swift cannot directly read an embedded HTML video's frames. All validation, player selection, movement interpretation, level holds, and UI remain Swift/SwiftUI. The adapter sends bounded numeric samples through a reply-controlled bridge and makes no downloads or persistent writes.

Reason: the user requested embedded videos after native-only tracking. Browser CORS/DRM restrictions are honored; inaccessible players retain playback/manual fallback. This replaces the earlier blanket website-tracking-unavailable behavior without claiming universal site compatibility.

Status: Accepted, Counter-specific.

## Counter ADR-003 — Manual Stages and Hard Time Budgets

Decision: keep manual stage scheduling in a pure, seeded Swift state machine, separate from live video analysis and UI/audio playback. Apply the user's latest correction as a hard Slow ≤20% cap per stage. Use prefix budgets for Slow and Ultrafast (≤50% of active program time) so early Bleepy completion cannot invalidate past time ratios. Slow's selection chance also decreases to a 20% floor when eligible.

Normal/Random initial stage lengths use ten-second granularity to accommodate minimum ten-second speed segments, including an explicit zero stage in Random. Bleepy effects have equal probability, one random event per five-minute program block, and forced Ultra waits for the next eligible/funded segment. Time edits apply to the next stage during a break; completion during a break skips the next stage. All state and sound synthesis remain in memory.

Status: Accepted, Counter-specific implementation choices for the requested manual program.

## Counter ADR-004 — Bounded Manual Programs and Playback Gating

Decision: manual rhythm now consists of 5–6 nonempty stages over 900–1200 seconds of running time, including inter-stage breaks. Both varied and fixed/consistent modes use this structure. Every stage starts below Ultra and has a protected terminal Ultra segment that grows from 10–15 seconds toward 30 seconds. Reserve terminal-Ultra time in the existing 50% cap; preserve the per-stage Slow≤20% cap. Bleepy edits redistribute remaining stage budgets or clamp to session/segment limits instead of violating the terminal segment or running indefinitely.

The user clarified “no sound” to mean **no video is playing**. Therefore gate timers/clicks/bar on playback state, not audio loudness, mute, or the existing beat-click toggle. Native playback uses timeControlStatus; embedded playback uses bounded HTML media state without audio capture or pixel reads. Reuse the existing click switch with soft, default-on clicks. The UI shows complete current segment duration rather than time to change.

Status: Accepted, supersedes ADR-003's unlimited/zero-stage and independent-video-clock behavior. Pauses do not count toward running duration; backgrounding/closing ends the program.

## Counter ADR-005 — Bleepy Is an Unrestricted Override

Decision: the user's latest correction makes Bleepy independent of ordinary duration/proportion/closing rules. Time changes apply directly to the active stage or break; exhausted timers complete immediately. Stage completion is immediate. Speed effects interrupt immediately and can extend the phase to fit their duration. They are never queued or cap-clamped. Consequently Bleepy may push actual program duration outside 15–20 minutes, exceed normal Slow/Ultra percentages, interrupt closing Ultra, or run a speed effect during a break. Normal rules still guide ordinary scheduling; video playback/user stop/pause and no-persistence behavior remain.

Add manual-only `RhythmLevel.superSlow` at half Slow's nominal target, used for the new 30-second outcome. All eleven outcomes are selected with equal probability, including the original four and the seven new ones. This supersedes the Bleepy constraint/queue portions of ADR-003/004.

Status: Accepted per explicit user correction.

## Counter ADR-006 — Bleepy Trigger Intervals and Reveal Order

Decision: replace fixed five-minute blocks with independent 60–300 second start-to-start trigger intervals. A trigger begins a three-second fortune-wheel reveal; its randomly chosen outcome remains pending and does not affect the program until the wheel settles. Stage/beat/break timing continues during the spin. Stop or completion cancels pending outcomes, and playback/manual pause freezes spin progress. Preserve equal odds and unrestricted outcome effects after reveal.

Status: Accepted per the user's latest Bleepy scheduling/presentation request.
