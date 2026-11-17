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
- `DIET-019` Implement Meal Reminders
- `DIET-020` Integrate Goal Setup and Sleep Setup into the app target
- Merged the onboarding draft UI into the launch flow and wired validation-backed draft state
- Merged the goal setup slice into the onboarding flow
- Merged the sleep setup slice into the onboarding flow
- Merged the weight logging/check-in slice into the app target
- Merged the meal reminders surface into the app target
- Merged the dashboard lane into the app target
- Added app routes and entry points for goal setup, sleep setup, and meal reminders
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

# In Progress

- None

# Blocked

- None

# Next Tasks

- Configure Google OAuth build settings for a device build if Drive backup is desired

# Dependency Tracking

- DIET-006 depends on the meal model and local persistence boundaries.
- DIET-010 depended on the weekly check-in data and trend summaries.

# Known Issues

- Unrelated uncommitted files remain in the working tree: `pass` and `pass.pub`
- Elevated hardening verification completed successfully after the sandbox-only restriction was bypassed
- Existing progress-photo metadata does not include rendered image assets, so comparison cards use privacy-safe placeholders
- `Dietum.xcodeproj/project.pbxproj` has an unrelated uncommitted Xcode-generated modification and remains intentionally untouched
- Google Drive is intentionally disabled until `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_REDIRECT_URI`, and `GOOGLE_OAUTH_SCHEME` are configured
- Phone usage is shown as unavailable until a separately authorized Family Controls / Screen Time integration is added; HealthKit only provides the in-bed intervals used for estimates

# Active Agents

- None

# Last Updated

2026-11-17
