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

## Known Problems

- Unrelated pre-existing Xcode scheme/project edits, `build/`, and `pass` / `pass.pub` remain uncommitted and were not staged.
- The latest device compile was blocked by the local SwiftData macro plugin returning malformed responses; the simulator service was also unavailable for XCTest execution.
- Added a regression test for staging a photo and generating editable estimates before save.
- The reminder-removal device compile was attempted but stopped at the existing SwiftData macro-plugin malformed-response failure before a complete app build.

## Exact Next Step

- Request Family Controls approval, then add the Device Activity report extension and connect its rendered usage report to the dashboard.
