# Dietum Product Specification

## Product Vision

Dietum helps one person track nutrition, body progress, and feedback loops in a way that is fast, private, and realistic for daily use on iPhone. The app should reduce friction around food logging and progress tracking while keeping the user in control of their nutrition targets.

## Target User

- A single personal user who wants local-only nutrition and progress tracking
- Someone who prefers quick meal logging, photo-assisted reminders, and simple adjustment guidance
- Someone who does not need accounts, social features, or cloud sync

## MVP Features

- Local user profile and body metrics
- Goal weight and goal date tracking
- Workout days and workout intensity
- Sleep information
- Meal count and preferred meal times
- Heavy and light meal preferences
- Daily calorie target and macro targets
- Editable calorie and macro targets
- Daily meal distribution
- Meal reminders
- Meal-photo capture
- Meal-food detection interface with a mock service first
- User correction of detected foods
- Weight logging
- Weekly check-in
- Front, back, left, and right progress photos
- Progress-photo comparison
- Weight and nutrition progress charts
- Suggested calorie adjustments that require user approval

## Out-Of-Scope Features

- Login
- User accounts
- Sign in with Apple
- Face ID
- Subscriptions
- Multiple users
- Cloud synchronization
- Cloud photo storage
- Social features
- Coach sharing
- Restaurant ordering
- Real-time grocery inventory
- Production analytics
- Web dashboard
- Android application

## Main Application Flows

1. Onboarding and profile setup
2. Home dashboard with daily targets and status
3. Meal logging with photo capture and food confirmation
4. Weight logging and weekly check-in
5. Progress photo capture and comparison
6. Nutrition review with suggested adjustments

## Onboarding Fields

- Name or nickname
- Height
- Current weight
- Goal weight
- Goal date
- Workout days
- Workout intensity
- Sleep information
- Meal count
- Preferred meal times
- Heavy meal preference
- Light meal preference
- Daily calorie target
- Protein target
- Carbohydrate target
- Fat target
- Fiber target

## Daily Dashboard Requirements

- Show today's calorie and macro targets
- Show meal count and meal distribution for the day
- Show reminder status
- Show logging shortcuts for meals, weight, and progress photos
- Show recent trend summaries for weight and nutrition
- Keep the screen readable and quick to scan

## Meal Logging Flow

- User opens the meal log flow from the dashboard or reminder
- User captures or attaches a meal photo
- The app shows detected foods from the analysis interface
- The user can correct, remove, or add foods
- The app stores the final meal entry locally
- The meal contributes to the daily nutrition summary

## Weekly Check-In Flow

- User reviews weight trend, adherence, and recent progress
- User enters or confirms weekly weight
- User can add notes about energy, hunger, and training
- The app may recommend calorie adjustments based on recent patterns

## Progress-Photo Flow

- User captures front, back, left, and right photos
- Photos are stored locally and associated with dates
- User can compare current photos with earlier entries
- The comparison should help the user notice body composition changes over time

## Nutrition-Adjustment Flow

- The app reviews recent weight and nutrition trends
- The app proposes a calorie adjustment if needed
- The user sees the reason and effect of the recommendation
- The user must approve the change before it becomes active

## Privacy Expectations For Personal Local Use

- Data stays on-device by default
- Health and photo data are not shared externally
- No account creation is required
- No cloud backup is assumed by default
- The app should minimize logging of private data

## Safety Constraints

- The app must not present meal detection as guaranteed accurate
- Nutrition recommendations should be framed as estimates
- Suggested calorie changes must never apply silently
- Users must remain in control of edits to their profile and targets
- The app should avoid overclaiming medical or clinical accuracy

## Phase 2 Ideas

- More advanced meal-photo assistance
- Better nutrition trend insights
- Habit streaks or adherence summaries
- Optional export of local data
- Improved progress photo comparison tools
- Smarter reminders based on user patterns

