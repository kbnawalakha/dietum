# Current Milestone

Milestone 0 — Repository and Architecture Foundation

# Completed

- Fixed physical-device signing configuration; signed iPhone build succeeded after Keychain approval.

- Product scope defined
- Multi-agent strategy defined
- Repository coordination setup
- Initial SwiftUI app shell scaffold
- Buildable Xcode project created
- `DIET-001` Create application shell
- Domain model foundation
- SwiftData foundation
- Navigation shell foundation
- Design-system foundation
- `DIET-006` Define meal logging flow
- `DIET-007` Add weekly check-in flow
- `DIET-008` Add progress-photo flow
- `DIET-009` Add nutrition-adjustment flow
- `DIET-010` Add weight and nutrition progress charts
- `DIET-011` Add user profile onboarding scaffolding and implementation planning
- `DIET-012` Implement goal setup
- `DIET-013` Implement sleep setup
- `DIET-015` Implement the Daily Dashboard
- `DIET-016` Implement Meal Logging
- `DIET-017` Implement Progress Photo Comparison
- `DIET-018` Implement Weight Logging
- `DIET-020` Integrate Goal Setup and Sleep Setup into the app target
- Merged the onboarding draft UI into the launch flow and wired validation-backed draft state
- Merged the goal setup slice into the onboarding flow
- Merged the sleep setup slice into the onboarding flow
- Merged the weight logging/check-in slice into the app target
- Merged the dashboard lane into the app target
- Removed the meal-reminder UI and navigation surface from the app; existing export/model compatibility remains local-only
- Removed the local export UI and navigation surface; export snapshot services remain available to the optional Drive backup path
- Added the XCTest target setup and deterministic nutrition-adjustment unit tests
- Added and hardened a lightweight GitHub Actions build workflow
- Completed Phase 2: advanced meal-photo assistance, nutrition trend insights, habit/adherence summaries, local data export, improved progress-photo comparison, and smarter reminders
- Completed MVP hardening: local meal-photo input, meal-entry persistence, live local export loading, and repository-backed meal save wiring
- Verified MVP hardening with a successful app build and XCTest run
- Added deterministic quality coverage for reminder controls, habit adherence, and local export payloads
- Added optional Google account sign-in, Keychain token storage, private Drive backup upload, skip flow, and weekly background scheduling
- Verified the optional account and backup flow with a successful build and 6-test XCTest run
- Updated lifestyle workout-day controls so activating a selected day deselects it
- Made the preferred meal-time text box grow and shrink with meal count
- Added calorie-based macro percentage and fiber-from-carbohydrates calculations to onboarding
- Added dashboard sleep/phone signals with HealthKit-derived wake time and seven-night inferred doom-scroll averages
- Hardened meal analysis cancellation and error handling, including clearing stale estimates when the description changes
- Fixed progress-photo library uploads so the selected pose remains associated while the PhotosPicker image loads asynchronously
- Added a user-triggered Screen Time authorization flow in Sleep Setup; Family Controls remains optional until Apple approval
- Grouped saved progress photos by capture date and added automatic regional body-fat estimates for chest, arms, legs, back, and visceral fat
- Relaxed body-photo analysis so valid uploaded images still receive an editable analysis when Vision pose detection is inconclusive
- Made meal-photo and body-photo analysis start automatically after upload, while keeping estimates editable before local save
- Fixed progress-photo picker timing so the selected pose is retained until PhotosUI delivers the image and the staged photo is analyzed
- Added date-grouped progress-photo deletion so users can remove every saved angle and its complete body analysis for one day without affecting other dates
- Fixed meal saving so selected meal photos persist with their nutrition entries, remain visible on today's meal page, and are available under Settings -> History -> Meal Photos with date-grouped daily totals and photo drill-down
- Added confirmation-required left-swipe deletion for saved progress-photo days and meal-photo history days
- Replaced fixed meal-analysis servings with per-100 g nutrition values, realistic default portions, editable gram weights, and persisted gram quantities on saved meal items
- Added between-photo progress comparison summaries showing overall and regional body-fat estimate changes in percentage points, with a visual-only fallback when comparable estimates are missing
- Replaced mock meal detection with Apple Vision food classification and USDA FoodData Central nutrition lookups; missing configuration now fails clearly instead of inventing calories
- Hardened meal tracking so description-based USDA lookup survives inconclusive photo classification, and repository save tests use an injected analyzer instead of requiring a live API key
- Hardened photo-only meal analysis by filtering generic Vision labels before limiting candidates and distinguishing rejected USDA keys from network failures

# In Progress

- Screen Time totals still require Apple approval for the Family Controls capability plus a Device Activity report extension

# Blocked

- None

# Next Tasks

- Request Family Controls capability approval in the Apple Developer account
- Add a Device Activity report extension to render authorized usage totals
- Configure Google OAuth build settings for a device build if Drive backup is desired
- Configure `USDA_FOOD_DATA_CENTRAL_API_KEY` in Xcode Build Settings for real meal-photo and description analysis

# Dependency Tracking

- DIET-006 depends on the meal model and local persistence boundaries.
- DIET-010 depended on the weekly check-in data and trend summaries.

# Known Issues

- Unrelated uncommitted files remain in the working tree: `pass` and `pass.pub`
- Elevated hardening verification completed successfully after the sandbox-only restriction was bypassed
- Progress-photo uploads are local-only; camera access still requires a physical device or a simulator camera configuration
- `Dietum.xcodeproj/project.pbxproj` has an unrelated uncommitted Xcode-generated modification and remains intentionally untouched
- Google Drive is intentionally disabled until `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_REDIRECT_URI`, and `GOOGLE_OAUTH_SCHEME` are configured
- Phone usage totals remain unavailable until the Family Controls capability is approved and a Device Activity report extension is added; HealthKit only provides the in-bed intervals used for estimates
- The default device build intentionally excludes Family Controls because the current provisioning profile does not include that capability
- Dashboard sleep signals now expose an explicit HealthKit refresh and Sleep Setup path; phone usage totals remain unavailable until Family Controls and a Device Activity report extension are provisioned
- Body-fat regional values are visual estimates, not clinical measurements; visceral fat cannot be measured from a photograph
- Vision pose detection can be inconclusive for cropped, dark, side-profile, or simulator images; those images now fall back to automatic general-range estimates instead of failing outright
- Current local Xcode verification can fail before app compilation when the SwiftData macro plugin returns a malformed response; rerun after CoreSimulator/Xcode services recover
- Progress-photo regression coverage now verifies staging and automatic estimate generation before save
- Meal reminders are no longer part of the active app surface; legacy reminder code remains only to preserve existing local export compatibility
- Local export is no longer an active user-facing feature; its snapshot service remains internal for Drive backup compatibility
- The export-removal compile check remains blocked by the local SwiftData macro-plugin malformed-response issue
- Nutrition insights now load the persisted active nutrition target and expose refresh/log-meal actions for empty or failed states
- Nutrition-insights compile verification is currently blocked by the local SwiftData macro-plugin malformed-response issue
- Profile onboarding is now gated to first launch with a persisted completion flag; profile edits and secondary navigation live in the ellipsis Settings hub, while meal tracking remains directly on the dashboard
- Settings-shell compile verification is currently subject to the local SwiftData macro-plugin malformed-response issue
- Progress-photo day deletion test execution is currently blocked when CoreSimulatorService has no available simulator destination
- Google sign-in requires real `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_REDIRECT_URI`, and matching `GOOGLE_OAUTH_SCHEME` build settings; placeholder values intentionally keep the button disabled
- Fixed `SwiftDataNutritionTargetRepository` protocol conformance by adding the missing active nutrition-target save adapter
- Elevated generic simulator build and test-bundle compilation now succeed; existing Swift concurrency warnings remain
- Meal-history `build-for-testing` verification succeeded; simulator test execution was not run in this pass
- Real meal analysis now requires `USDA_FOOD_DATA_CENTRAL_API_KEY`; Vision identifies likely food labels, while USDA supplies per-100 g nutrition. A 2D photo cannot reliably infer exact portion weight, cooking oils, or hidden ingredients, so the editable estimate remains required
- Body-photo comparisons now report changes from saved non-clinical estimates; they do not claim to measure visual or clinical body composition from pixels
- If the USDA key is not configured, the meal screen will intentionally show a configuration error rather than create a fake estimate
- Photo analysis still requires a valid USDA key and network access; HTTP 401/403 responses now identify invalid key configuration directly

# Active Agents

- None

# Last Updated

2026-11-17

## Separate Local App — Counter (2026-11-17)

- User-assigned task: build an iPhone-only video-link player named Counter, without publishing to GitHub.
- Added an independent Xcode project under `Counter/`; Dietum app source is unchanged.
- Native direct-stream playback, embedded website playback, manual player switching, link validation, loading/error/offline states, and reload/close controls implemented.
- Unsigned generic iPhone build succeeded; 13 resolver checks passed. Simulator service unavailable; device installation and real website playback remain unverified.
- No pre-existing Counter test baseline existed. Dietum tests are unrelated to this independent project and were not run.

### Counter manual rhythm overlay (2026-11-17)

- Added a compact overlay over both inline players, manual 30–240 BPM controls, start/stop, visual pulse/four-beat count, and optional synthesized click audio.
- Metronome uses monotonic deadlines and drops missed beats after stalls; closes/stops on player close or app inactivity. Rhythm is independent of video playback.
- System fullscreen/Picture in Picture do not include the inline overlay. Live-device audio and interaction verification remain outstanding.
- Final overlay verification: unsigned iPhone build succeeded with Xcode plugin access; existing 13 link checks and whitespace checks passed.

### Counter no-history requirement (2026-11-17)

- Confirmed no link persistence, analytics, URL logging, or restored sessions in Counter; embedded websites already use nonpersistent WebKit storage.
- Closing the player now also clears the URL input; added a visible no-history notice and README explanation.
- Video-synchronized guidance was subsequently selected as audio plus movement; see the direct-video synchronization update below.

### Counter direct-video synchronization (2026-11-17)

- User selected audio beat plus visible movement, starting with direct videos.
- Added protocol-based on-device analysis for direct MP4/M4V/MOV, audio RMS peaks, sampled frame-difference peaks, and selectable Audio/Movement/Both cue timelines with local BPM estimates.
- Overlay follows native playback time rather than an independent clock; no inferred beats are inserted in pauses/gaps. Manual metronome remains available.
- Analysis uses ephemeral downloads capped at 150 MiB and 10 minutes; media cleanup and task cancellation are implemented. Links/results are not persisted.
- Synthetic signal and generated-media decoding checks passed. iPhone/network playback accuracy and specific action recognition remain unverified; semantic stroke-pattern recognition is not implemented. HLS/website analysis remains unsupported.
- Final synchronization validation: iPhone build succeeded; 13 link checks, 18 rhythm checks, and generated-media/loopback HTTP integration checks passed (including temporary-file decoding, size rejection, HTTP errors, cleanup, and cancellation).

### Counter movement-led bar and stable levels (2026-11-17)

- Replaced automatic cue flashes with a vertical up/down bar and Stop/Slow/Normal/Fast/Ultrafast levels; manual mode also uses a bar and speed presets.
- Whole-video classification weights movement 85% and audio 15%; static sections remain Stop. All automatic sections last strictly over 10 seconds, including the tail; short videos explain the minimum length.
- Target cycle rates 0/40/80/120/180 BPM are fitted to whole cycles per section. A section preview shows the complete video plan. Classification is based on movement estimates, not semantic action recognition.
- Final bar validation: iPhone build, existing link/rhythm tests, new section/cycle tests, generated-media/HTTP regressions, and whitespace checks passed; physical-device visual checks remain.

### Counter streaming-only analysis (2026-11-17)

- Replaced whole-file downloads/AVAssetReader analysis with live native-player frame observation and an optional pass-through audio-energy tap.
- No app-created video files or separate analysis requests. Evidence is bounded to a small previous-frame grid, one audio reading, and four seconds/64 numeric samples in memory. Legacy analysis files are deleted on launch.
- Live five-level bar observes movement, holds levels at least 11 playback seconds, and completes cycles before changes. Seeks reset observation; pause freezes it. The entire-future-video plan and size/duration caps are removed.
- This supersedes prior full-video/download-based Counter behavior. System-managed streaming buffers remain; native live audio/protected-stream support and iPhone visual/CPU checks remain unverified.
- Final streaming verification: iPhone build, link/signal/live-meter checks, in-memory frame/output lifecycle tests, source persistence checks, and whitespace checks passed.

### Counter device-build signing fix (2026-11-17)

- Reproduced the user's default device-build failure: Counter required a development team.
- Configured Debug/Release with the existing Dietum development team and Counter's own `com.kbnawalakha.Counter` bundle identifier; automatic provisioning enabled.
- Signed generic iPhone build succeeded. Physical installation/playback still needs Xcode Run on the user's phone.

### Counter video-reference timing correction (2026-11-17)

- Fixed the automatic bar using preset BPM after movement selected a label. Bar cadence now comes only from measured movement-peak intervals, and phase is anchored to those video timestamps.
- Requires consistent video peaks, interpolates at most one measured cycle, then waits for fresh evidence. Constant unpatterned motion or audio alone cannot drive automatic oscillation. Labels retain minimum holds separately.
- Native streams now start tracking automatically. Website players explicitly show tracking unavailable and require opt-in for a manual meter.
- Signed iPhone build and signal/frame regressions passed; real iPhone/video alignment still needs verification.

### Counter embedded website tracking (2026-11-17)

- Added best-effort live movement tracking for HTML videos inside WebKit pages, iframes, and open shadow roots. Native and embedded sources share the motion-timed bar engine.
- Isolated-world reply-controlled bridge passes only bounded numeric frame samples and playback state. No media files, saved links, stream extraction, or protection bypass.
- Blocked frame access is explicit; manual mode remains opt-in. Pause, seek, navigation, player switching, backgrounding, and teardown reset/suspend tracking as appropriate.
- Signed iPhone build, bridge/script checks, and actual macOS WebKit top-level/iframe live-video integration passed. External sites and iPhone embedded playback still need device verification.

### Counter manual stage program (2026-11-17)

- Added Normal (2–4 minute) / Random (0–4 minute) stages, 10–30 second changing speed segments, and 15–30 second breaks.
- Applied the user's corrected hard Slow cap of 20% per stage, plus decreasing eligible Slow chance to a 20% floor. Ultrafast stays within 50% of active program time using prefix budgets.
- Added randomized five-minute-block Bleepy scheduling, equal-probability time −30/+30, stage completion, and queued 15–30 second Ultra effects; beep and visible notices included.
- Manual toggle now works for native and embedded playback. Settings expose stages/fixed tempo, duration mode, pause/resume/end, and click/Bleepy sound controls.
- Signed iPhone build and seeded scheduler tests passed, including 50 one-hour cap simulations. Physical-device timing/audio checks remain; no saved videos/links/program history and no push.

### Counter bounded manual programs and playback gating (2026-11-17)

- Manual programs now finish after 15–20 running minutes with 5–6 varying nonempty stages and 15–30 second breaks. Fixed tempo also uses consistent stages.
- Every stage starts below Ultra and finishes with protected Ultra, growing from 10–15 seconds toward 30 seconds. Slow≤20% per stage and Ultra≤50% active time remain enforced, including Bleepy adjustments.
- Applied clarification: manual rhythm pauses when **no video is playing**; silent/muted playback and disabling clicks do not pause it. Native state and embedded playback-only metadata feed a stale-safe gate.
- Reused the existing click toggle, now soft and on by default. Replaced Change in with current beat-segment duration.
- 200-seed program/gate tests and real WebKit muted-play/pause checks pass. Signed iPhone build passes; actual phone UI/audio checks remain.

### Counter embedded-video input (2026-11-17)

- Added Link / Embedded video input selection with a multiline embed field.
- Accepts embed URLs and iframe/video/source HTML; extracts and validates only the player src URL, decodes entities/protocol-relative sources, and routes embedded mode through WebKit.
- Pasted markup/scripts are not rendered; malformed/source-less and non-HTTP(S) inputs are rejected. Existing no-storage/no-history behavior remains.
- Embed parser regressions and signed iPhone build passed; actual provider/device playback remains a manual check.
