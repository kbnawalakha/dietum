# Active Handoff

## Date

2026-11-17

## Assigned Issue

Group progress photos by date and persist regional body-fat estimates

## Branch

codex/repo-foundation

## Work Completed

- Added `BodyFatEstimateBreakdown` for chest, arms, legs, back, and visceral estimates.
- Persisted the optional breakdown through the SwiftData progress-photo model.
- Added editable regional estimate fields and automatic general-range suggestions after body analysis.
- Changed valid-image analysis fallback so Vision pose-detection misses no longer block estimates or make the Analyze button appear broken.
- Grouped saved progress-photo rows by capture date.

## Files Changed

- `Dietum/Domain/Models/DomainModelPlaceholder.swift`
- `Dietum/Data/SwiftData/Models/StoredProgressPhotoMetadata.swift`
- `Dietum/Features/ProgressPhotos/ProgressPhotosViewModel.swift`
- `Dietum/Features/ProgressPhotos/ProgressPhotosView.swift`
- `Dietum/DietumTests/NutritionAdjustmentRecommendationServiceTests.swift`
- `PROJECT_STATUS.md`
- `HANDOFF.md`

## Verification

- Feature build: `xcodebuild build -project Dietum.xcodeproj -scheme Dietum -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-body-fat-build` succeeded.
- Final: `xcodebuild test -project Dietum.xcodeproj -scheme Dietum -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/dietum-body-fat-tests` passed with 17 tests and 0 failures.
- Sleep-signal update: `xcodebuild build -project Dietum.xcodeproj -scheme Dietum -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/dietum-sleep-signals-device CODE_SIGNING_ALLOWED=NO` succeeded.
- The refreshed simulator test command was attempted but could not start because CoreSimulatorService was unavailable and no simulator destination was discoverable in this environment.
- `git diff --check` passed.

## Work Remaining

- Body-fat regional values are estimates and should be replaced or edited with measured data when available.
- Vision pose detection remains best-effort; valid images with inconclusive framing use an editable general-range fallback.
- Actual Screen Time totals are not yet available because the project does not have a Device Activity report extension.
- The default device build uses the existing HealthKit-only profile; Screen Time authorization remains unavailable until Family Controls is enabled in Apple Developer and Xcode.
- Dashboard sleep signals now have a visible refresh action and a direct Sleep Setup route; phone usage remains clearly marked as unavailable until the Screen Time capability and report extension exist.
- Meal and body-photo uploads now trigger local estimates automatically; the detected foods, macros, body-fat ranges, and regional values remain editable before saving.
- Progress-photo picker selection now retains its pose through PhotosUI dismissal and awaits staging plus analysis before clearing the selection.
- Removed meal-reminder navigation and dashboard entry points per product direction; legacy reminder model/export types remain only for local compatibility.
- Removed local-export navigation and dashboard entry points; retained snapshot services because the optional Drive backup uses them internally.
- Profile onboarding is now a first-launch flow; the dashboard Quick Start and crowded toolbar were replaced by an ellipsis Settings hub for profile edits and all secondary routes.

## Known Problems

- Unrelated pre-existing Xcode scheme/project edits, `build/`, and `pass` / `pass.pub` remain uncommitted and were not staged.
- The latest device compile was blocked by the local SwiftData macro plugin returning malformed responses; the simulator service was also unavailable for XCTest execution.
- Added a regression test for staging a photo and generating editable estimates before save.
- The reminder-removal device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure before a complete app build.
- The export-removal device compile was attempted and hit the same existing SwiftData macro-plugin malformed-response failure before a complete app build.
- Nutrition insights now receive the live SwiftData target repository and provide explicit refresh and log-meal actions.
- Nutrition-insights device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure.
- Settings-shell device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure.

## Exact Next Step

- Request Family Controls approval, then add the Device Activity report extension and connect its rendered usage report to the dashboard.

## Counter — Separate Local App (2026-11-17)

User requested an independent iPhone-only video-link player called Counter and no GitHub publication. Added `Counter/Counter.xcodeproj/project.pbxproj`, `Counter/Counter/{CounterApp.swift,LinkResolver.swift,WebsitePlayer.swift,Info.plist}`, `Counter/Tests/main.swift`, and `Counter/README.md`; updated `PROJECT_STATUS.md` and this handoff. Existing Dietum changes and unrelated untracked files were left untouched.

Validation: unsigned generic iOS build succeeded, and 13 standalone URL-validation/routing checks passed. No existing Counter baseline was available. Simulator discovery failed because CoreSimulatorService was inaccessible. Initial project-generation Python failed due to f-string quoting; corrected. First project build failed because a dictionary was used as a build-setting value; moved ATS settings into Info.plist. Initial test compile failed because throwing expressions were inside assert autoclosures; corrected and reran successfully.

Remaining: choose signing team/bundle ID in Xcode, install on the user's iPhone, and verify direct MP4/HLS, website controls, fullscreen rotation, and offline retry. Website/DRM restrictions prevent guaranteed universal playback. No GitHub push, per user request. Next step: open `Counter/Counter.xcodeproj`, configure signing, and run on iPhone.

### Counter manual metronome overlay (2026-11-17)

Assigned request: add a manual BPM metronome overlay to Counter. Changed `Counter/Counter/CounterApp.swift`, added `Counter/Counter/MetronomeOverlay.swift`, registered it in `Counter/Counter.xcodeproj/project.pbxproj`, and updated `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff. Added tempo settings (30–240), visual pulse and four-beat count, start/stop, optional in-memory synthesized click audio, and lifecycle cancellation. No GitHub push requested or performed.

Baseline: unsigned iPhone build and 13 existing link checks passed before edits. Initial overlay build failed because the sandbox prevented the SwiftUI State macro plugin from returning a valid response; retried with Xcode plugin access. Device checks still needed: sound/video mixing, timing under load, tempo interaction, website controls, and background/close cancellation. The overlay is inline only and does not follow system fullscreen or Picture in Picture. Next step: run Counter on the user's iPhone and test the manual rhythm overlay with actual video playback.

Final overlay verification: elevated unsigned generic iPhone build succeeded; 13 link checks and `git diff --check` passed. Existing unrelated Dietum source/scheme edits were not included. Local Git metadata requires elevated access to create the commit; no remote push will be made.

### Counter no saved historical links (2026-11-17)

Assigned request: do not save historical links. Inspected all Counter sources: current URL is memory-only, WebKit uses a nonpersistent data store, and there is no history persistence or URL logging. Changed `Counter/Counter/CounterApp.swift` to clear input on player close and show a no-history notice; updated `Counter/README.md`, `PROJECT_STATUS.md`, and this handoff. Baseline iPhone build and 13 URL checks passed. No unrelated Dietum changes were included; no push requested.

Remaining: test close/relaunch and WebKit storage on an actual phone. The user's separate video-synchronization request remains unimplemented pending selection of audio beat, visible motion, or timeline cues. Website/network-provider records are outside Counter's control.
