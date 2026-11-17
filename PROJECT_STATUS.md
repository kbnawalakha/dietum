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
- Grouped saved progress photos by capture date and added editable regional body-fat estimates for chest, arms, legs, back, and visceral fat
- Relaxed body-photo analysis so valid uploaded images still receive an editable analysis when Vision pose detection is inconclusive
- Made meal-photo and body-photo analysis start automatically after upload, while keeping estimates editable before local save
- Fixed progress-photo picker timing so the selected pose is retained until PhotosUI delivers the image and the staged photo is analyzed

# In Progress

- Screen Time totals still require Apple approval for the Family Controls capability plus a Device Activity report extension

# Blocked

- None

# Next Tasks

- Request Family Controls capability approval in the Apple Developer account
- Add a Device Activity report extension to render authorized usage totals
- Configure Google OAuth build settings for a device build if Drive backup is desired

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
- Vision pose detection can be inconclusive for cropped, dark, side-profile, or simulator images; those images now fall back to editable estimates instead of failing outright
- Current local Xcode verification can fail before app compilation when the SwiftData macro plugin returns a malformed response; rerun after CoreSimulator/Xcode services recover
- Progress-photo regression coverage now verifies staging and editable estimate generation before save
- Meal reminders are no longer part of the active app surface; legacy reminder code remains only to preserve existing local export compatibility
- Local export is no longer an active user-facing feature; its snapshot service remains internal for Drive backup compatibility
- The export-removal compile check remains blocked by the local SwiftData macro-plugin malformed-response issue
- Nutrition insights now load the persisted active nutrition target and expose refresh/log-meal actions for empty or failed states
- Nutrition-insights compile verification is currently blocked by the local SwiftData macro-plugin malformed-response issue
- Profile onboarding is now gated to first launch with a persisted completion flag; profile edits and secondary navigation live in the ellipsis Settings hub, and Dashboard Quick Start has been removed
- Settings-shell compile verification is currently subject to the local SwiftData macro-plugin malformed-response issue

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
- Video-synchronized rhythm guidance remains a separate pending request: audio beat vs. visible motion vs. manually marked timeline has not yet been selected or implemented.
