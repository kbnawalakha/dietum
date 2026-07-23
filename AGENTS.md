# Shared Agent Instructions

This document applies to every coding agent working on Dietum.

## Before Starting

Every agent must:

1. Read `PRODUCT_SPEC.md`.
2. Read `ARCHITECTURE.md`.
3. Read `PROJECT_STATUS.md`.
4. Read `HANDOFF.md`.
5. Read `DECISIONS.md`.
6. Read the assigned issue.
7. Inspect the current branch.
8. Inspect recent commits.
9. Run relevant tests before modifying code.

## Scope Rules

- Work only on the assigned issue.
- Do not implement unrelated improvements.
- Do not duplicate existing types.
- Do not rename shared models without approval.
- Do not change architecture without documenting the decision.
- Do not add login, cloud sync, Face ID, or subscriptions.
- Keep the current version local-first.
- Avoid editing files owned by another active issue.

## Engineering Rules

- Use Swift and SwiftUI only for app code.
- Use SwiftData for local persistence.
- Keep business logic outside views.
- Use protocol-based replaceable services.
- Use Swift Concurrency for asynchronous work.
- Use typed errors.
- Prefer reusable components.
- Include loading, empty, error, and offline states where relevant.
- Add accessibility labels where needed.
- Do not add hard-coded API keys.
- Do not log sensitive health or photo data.

## Coordination Rules

- Read the active issue before editing code.
- Check the branch name and recent commits before starting work.
- Respect file ownership and do not overlap another agent's area without coordination.
- Update `PROJECT_STATUS.md` and `HANDOFF.md` when work status changes.
- Record any blocked dependencies or missing decisions early.

## Completion Rules

Before stopping, every agent must:

1. Run relevant tests.
2. Commit completed work.
3. Push the branch when possible.
4. Update `HANDOFF.md`.
5. List files changed.
6. State what remains unfinished.
7. Record failed commands.
8. Avoid marking incomplete work as done.

## Usage-Limit Interruption Rule

If work stops because of a usage or context limit:

- Preserve compiling work when possible.
- Commit with a clear `WIP:` message if necessary.
- Update `HANDOFF.md`.
- Document the exact next step.
- Leave the task marked in progress.
- Do not restart the task from scratch during the next session.

