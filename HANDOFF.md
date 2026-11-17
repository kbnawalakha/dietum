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
- `git diff --check` passed.

## Work Remaining

- Body-fat regional values are estimates and should be replaced or edited with measured data when available.
- Vision pose detection remains best-effort; valid images with inconclusive framing use an editable general-range fallback.
- Actual Screen Time totals are not yet available because the project does not have a Device Activity report extension.
- The default device build uses the existing HealthKit-only profile; Screen Time authorization remains unavailable until Family Controls is enabled in Apple Developer and Xcode.

## Known Problems

- Unrelated pre-existing Xcode scheme/project edits, `build/`, and `pass` / `pass.pub` remain uncommitted and were not staged.

## Exact Next Step

- Request Family Controls approval, then add the Device Activity report extension and connect its rendered usage report to the dashboard.
