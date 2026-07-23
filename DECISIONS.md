# Decision Log

## ADR-001 — Local-First Application

Decision:

Dietum will initially be a single-user local iPhone application.

Reason:

The initial product is for personal use and does not require authentication or synchronization.

Status:

Accepted.

## ADR-002 — SwiftData Persistence

Decision:

Use SwiftData for structured local persistence.

Reason:

It integrates directly with SwiftUI and is sufficient for the current MVP.

Status:

Accepted.

## ADR-003 — Mock Meal Analysis First

Decision:

Build meal-photo analysis behind a protocol and begin with a deterministic mock service.

Reason:

This allows UI and data flows to be completed before selecting or paying for a production AI service.

Status:

Accepted.

## ADR-004 — User-Approved Calorie Changes

Decision:

Nutrition-target adjustments must be proposed to the user and cannot silently modify the active plan.

Reason:

Nutrition recommendations are estimates and must remain user-controlled.

Status:

Accepted.

