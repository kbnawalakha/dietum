# Dietum Architecture

## Architecture Goals

- Keep the app local-first and easy to reason about
- Separate UI, business logic, persistence, and external services
- Make core behaviors replaceable through protocols
- Support multiple coding agents without overlapping ownership
- Keep meal analysis and other non-deterministic behavior behind mocks first

## Technology Stack

- Swift
- SwiftUI
- SwiftData
- Swift Concurrency

## State Management Approach

Dietum uses an MVVM-style architecture with feature-scoped view models.

- Views render state and send user intent
- View models coordinate screen state and call use cases
- Use cases contain business rules and orchestration
- Repositories abstract persistence
- Services abstract analysis, formatting, and other replaceable behaviors

## Layer Dependency Rules

Allowed dependency direction:

```text
Views
  ↓
View Models
  ↓
Use Cases
  ↓
Repository Protocols
  ↓
Repository Implementations
  ↓
SwiftData and Services
```

Additional rules:

- Views must not perform nutrition calculations.
- Views must not read or write SwiftData directly except through approved lightweight patterns.
- Views must not do file storage or image analysis.
- View models may not depend on concrete repository implementations.
- Use cases may depend only on protocols and pure domain types.
- Repository implementations may depend on SwiftData and filesystem services.
- Shared domain models must stay framework-light and should not import SwiftUI.

## Folder Organization

Use feature-based organization with shared core modules for domain and infrastructure concerns.

Example structure:

```text
Dietum/
  App/
  Features/
    Onboarding/
    Dashboard/
    Meals/
    CheckIn/
    Progress/
    Settings/
  Domain/
    Models/
    UseCases/
    Services/
    Repositories/
  Data/
    SwiftData/
    FileStorage/
  Support/
    DesignSystem/
    Navigation/
    Logging/
    DependencyInjection/
  Tests/
```

## Dependency Injection

- Use initializer injection for view models and use cases.
- Provide feature dependencies from a small app-level composition root.
- Prefer protocol-driven dependencies over global singletons.
- Keep dependency wiring in one place so mock and production services can be swapped easily.

## Navigation Approach

- Use a top-level `NavigationStack` for the main app flow.
- Model navigation with typed routes or a route enum per feature when needed.
- Keep route construction out of the views that only display content.
- Preserve the ability to coordinate onboarding, dashboard, and detail flows without hidden side effects.

## Local Image Storage Strategy

- Store captured meal and progress images on disk in the app container, not in SwiftData blobs.
- Save lightweight metadata in SwiftData, including timestamps, category, and file references.
- Use stable relative paths or identifiers so records remain resilient to app launches.
- Generate thumbnails or derived previews when needed rather than duplicating originals in the database.
- Treat photo data as private local data and avoid logging its contents.

## Error Handling Conventions

- Use typed errors for domain and infrastructure failures.
- Map low-level errors to user-facing states at the boundary.
- Surface loading, empty, error, and offline states when relevant.
- Prefer actionable error messages over generic failure text.
- Keep retry behavior explicit in the view model or use case layer.

## Logging Restrictions

- Do not log sensitive health information.
- Do not log photo contents or file paths that could expose private data unnecessarily.
- Do not hard-code API keys.
- Keep debug logs minimal and temporary.
- Logging should help diagnose state transitions, not inspect private user data.

## Testing Approach

- Unit test use cases for business logic.
- Unit test view models for state transitions and error mapping.
- Unit test repository adapters when they contain non-trivial logic.
- Add integration tests for SwiftData behavior once the persistence layer exists.
- Keep mock services deterministic so tests are repeatable.

## Mock-Service Strategy

- Define meal-analysis and other external behaviors behind protocols from the start.
- Start with deterministic mock implementations for UI and workflow development.
- Make mock data representative enough to exercise correction, error, and empty states.
- Replace mock services with production services without changing view code.

## Naming Conventions

- Use feature names consistently across folders, types, and routes.
- Name view models after the screen or feature they support.
- Name use cases by action, such as `LogMealUseCase`.
- Name repository protocols by capability, such as `MealRepository`.
- Name concrete implementations clearly, such as `SwiftDataMealRepository`.
- Keep shared models singular and intention-revealing.

## Shared Domain Model Rules

- Shared domain models belong in the domain layer and should be reusable across features.
- Shared models should avoid UI-specific formatting and view state.
- Shared models should be stable and not renamed casually.
- Any change to a shared model must be documented in `DECISIONS.md` or the issue that owns the change.
- Do not duplicate shared models in feature folders when a common domain type already exists.

