# Dietum

Dietum is a personal-use iPhone nutrition and progress-tracking app. The repo now includes a buildable Xcode project and a SwiftUI app shell. The product direction stays local-first, Swift-based, and centered on helping one user track meals, weight, progress photos, and nutrition targets. Account sign-in and Google Drive backup are optional; users can skip them and keep using the app locally.

## MVP Scope

- Local user profile
- Height and weight entry
- Goal weight and goal date
- Workout days and workout intensity
- Sleep information
- Meal count and preferred meal times
- Heavy and light meal preferences
- Daily calorie target and macro targets
- User-editable calories and macros
- Daily meal distribution
- Meal-photo capture
- Meal-food detection UI backed by a mock service first
- User correction of detected foods
- Weight logging
- Weekly check-in
- Front, back, left, and right progress photos
- Progress-photo comparison
- Weight and nutrition progress charts
- Suggested calorie adjustments with user approval before applying them
- Optional Google sign-in with private weekly Google Drive backups

## Technology Choices

- Swift
- SwiftUI
- SwiftData for local persistence
- Swift Concurrency for async work
- Protocol-based services with dependency injection
- Mock services for meal analysis during the first implementation

## Current Development Status

The repository now contains the coordination foundation, a buildable Xcode project, the SwiftUI app shell, SwiftData persistence, the complete MVP feature set, Phase 2 enhancements, local-only hardening, deterministic quality coverage, and the optional account/backup flow. The code builds on the iOS simulator and remains local-first when account setup is skipped.

## How To Open And Run

Open `Dietum.xcodeproj` in Xcode, select an iPhone simulator target, and run the `Dietum` scheme.

## Optional Google Drive Setup

The account screen is usable without configuration: tap **Skip for now** to stay local-only. To enable Google sign-in and weekly Drive backups, create a Google OAuth iOS client and set these build settings for the `Dietum` target:

- `GOOGLE_OAUTH_CLIENT_ID` - the Google OAuth client ID
- `GOOGLE_OAUTH_REDIRECT_URI` - the registered custom-scheme redirect URI
- `GOOGLE_OAUTH_SCHEME` - the URL scheme used by that redirect URI

For an iOS OAuth client, the redirect URI normally looks like `com.googleusercontent.apps.1234567890:/oauthredirect`; set `GOOGLE_OAUTH_SCHEME` to the exact scheme before the `:/oauthredirect` portion. The scheme must be registered in the Google Cloud OAuth client and must match the app’s `CFBundleURLSchemes` value. If these settings remain as `$(...)` placeholders, the Google button stays disabled by design.

The app requests the private `drive.appdata` scope and stores OAuth tokens in the iOS Keychain. Weekly backup scheduling uses `BGTaskScheduler`; iOS decides when an eligible background refresh runs.

## How To Run Tests

Run the `Dietum` scheme with an iPhone Simulator. The current suite contains 5 deterministic XCTest cases and should report 0 failures.

## Repository Structure

At the moment, the repository includes documentation and a lightweight source scaffold:

- `README.md` - project overview and setup notes
- `PRODUCT_SPEC.md` - product requirements and user-facing scope
- `ARCHITECTURE.md` - technical architecture and dependency rules
- `AGENTS.md` - shared operating rules for coding agents
- `CLAUDE.md` - Claude-specific review guidance
- `PROJECT_STATUS.md` - milestone and backlog snapshot
- `HANDOFF.md` - reusable handoff template
- `DECISIONS.md` - architectural decision log
- `PULL_REQUEST_GUIDELINES.md` - review and pull request guidance
- `.github/ISSUE_TEMPLATE/` - GitHub issue templates
- `.github/pull_request_template.md` - pull request template
- `Dietum.xcodeproj/` - Xcode project for the iPhone app target
- `Dietum/` - initial SwiftUI app shell and feature folders
- `Dietum/Features/Meals/` - meal logging UI shell and mock-analysis flow
- `Dietum/Features/CheckIn/` - weekly check-in screen and view model
- `Dietum/Features/ProgressPhotos/` - progress-photo staging and review flow
- `Dietum/Features/Charts/` - progress chart visualizations for weight and nutrition
- `Dietum/Features/NutritionAdjustment/` - calorie adjustment review and approval flow
- `Dietum/Features/Onboarding/` - user profile onboarding draft flow and launch gate
- `Dietum/App/AccountFeature.swift` - optional Google account and weekly Drive backup flow
- `Dietum/Features/Dashboard/` - state-driven daily dashboard
- `Dietum/Data/` - SwiftData models, persistence stack, and repository adapters

## References

- Product specification: [PRODUCT_SPEC.md](./PRODUCT_SPEC.md)
- Shared agent instructions: [AGENTS.md](./AGENTS.md)
