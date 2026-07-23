# Dietum

Dietum is a personal-use iPhone nutrition and progress-tracking app. The current product direction is local-first, Swift-based, and centered on helping one user track meals, weight, progress photos, and nutrition targets without accounts or cloud sync.

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
- Meal reminders
- Meal-photo capture
- Meal-food detection UI backed by a mock service first
- User correction of detected foods
- Weight logging
- Weekly check-in
- Front, back, left, and right progress photos
- Progress-photo comparison
- Weight and nutrition progress charts
- Suggested calorie adjustments with user approval before applying them

## Technology Choices

- Swift
- SwiftUI
- SwiftData for local persistence
- Swift Concurrency for async work
- Protocol-based services with dependency injection
- Mock services for meal analysis during the first implementation

## Current Development Status

The repository currently contains the coordination and architecture foundation only. No Xcode project structure has been verified yet, and no app features have been implemented in this repository snapshot.

## How To Open And Run

The app shell has not been created yet. Once the Xcode project or workspace is added, open it in Xcode, select an iPhone simulator target, and run the app from the main scheme.

## How To Run Tests

Automated app tests have not been added yet. When the first test target exists, run it from Xcode or with the appropriate `xcodebuild test` command for the selected scheme.

## Repository Structure

At the moment, the repository is documentation-first:

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

## References

- Product specification: [PRODUCT_SPEC.md](./PRODUCT_SPEC.md)
- Shared agent instructions: [AGENTS.md](./AGENTS.md)

