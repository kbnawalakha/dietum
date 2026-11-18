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
