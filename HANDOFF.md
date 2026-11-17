# Active Handoff

## Date

2026-11-17

## Assigned Issue

Dashboard sleep and phone-use signals

## Branch

codex/repo-foundation

## Work Completed

- Extended the HealthKit sleep importer to distinguish bedtime, sleep onset, wake time, and out-of-bed time.
- Added inferred pre-sleep and post-wake doom-scroll durations from those intervals.
- Added seven-night averaging and today wake-time loading to the dashboard view model.
- Added dashboard cards for phone usage, wake time, and both inferred doom-scroll averages.
- Kept phone usage explicitly unavailable because ordinary iOS apps cannot read Screen Time totals without the separate Family Controls capability.
- Added deterministic dashboard coverage for the average calculations and formatted values.

## Files Changed

- `Dietum/Features/Onboarding/HealthKitSleepService.swift`
- `Dietum/Features/Dashboard/DashboardViewModel.swift`
- `Dietum/Features/Dashboard/DashboardView.swift`
- `Dietum/DietumTests/NutritionAdjustmentRecommendationServiceTests.swift`
- `PROJECT_STATUS.md`
- `HANDOFF.md`

## Verification

- Baseline: `xcodebuild test -project Dietum.xcodeproj -scheme Dietum -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/dietum-baseline-tests` passed with 16 tests and 0 failures.
- Feature build: `xcodebuild build -project Dietum.xcodeproj -scheme Dietum -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/dietum-dashboard-build` succeeded.
- Final: `xcodebuild test -project Dietum.xcodeproj -scheme Dietum -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath /private/tmp/dietum-dashboard-tests-2` passed with 17 tests and 0 failures.
- `git diff --check` passed.

## Work Remaining

- Actual phone-usage totals require a separately authorized Screen Time / Family Controls integration; the dashboard currently shows `Unavailable` rather than fabricating a number.
- Google OAuth build settings still need to be configured before real Drive backup can be exercised on a device.

## Known Problems

- Unrelated pre-existing Xcode scheme/project edits and `pass` / `pass.pub` remain uncommitted and were not staged.
- HealthKit-derived doom-scroll values are estimates of time in bed before sleep and after wake, not proof that the screen was active.

## Exact Next Step

- Configure Google OAuth for device testing, then decide whether to pursue the separate Family Controls entitlement for real Screen Time totals.
