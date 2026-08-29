import Foundation
import SwiftUI

struct MealReminderSchedule: Hashable, Sendable {
    var mealType: MealType
    var time: DateComponents
    var isEnabled: Bool

    init(
        mealType: MealType,
        hour: Int,
        minute: Int = 0,
        isEnabled: Bool = true
    ) {
        self.mealType = mealType
        self.time = DateComponents(hour: hour, minute: minute)
        self.isEnabled = isEnabled
    }

    var displayTime: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short

        var components = DateComponents()
        components.hour = time.hour
        components.minute = time.minute
        let calendar = Calendar.current
        let date = calendar.date(from: components) ?? .now
        return formatter.string(from: date)
    }
}

struct MealReminderStatus: Hashable, Sendable {
    var title: String
    var detail: String
    var symbolName: String
    var isPositive: Bool
}

struct MealReminderInsight: Hashable, Sendable {
    struct Recommendation: Hashable, Sendable {
        var title: String
        var detail: String
        var reasons: [String]
        var proposedSchedules: [MealReminderSchedule]
        var actionTitle: String
    }

    var headline: String
    var summary: String
    var patternLabel: String
    var patternScore: Int
    var nextReminderText: String
    var controlNote: String
    var supportingSignals: [String]
    var recommendation: Recommendation?
}

protocol MealReminderInsightService {
    func makeInsight(
        from schedules: [MealReminderSchedule],
        permissionGranted: Bool,
        now: Date
    ) -> MealReminderInsight
}

struct DeterministicMealReminderInsightService: MealReminderInsightService {
    func makeInsight(
        from schedules: [MealReminderSchedule],
        permissionGranted: Bool,
        now: Date
    ) -> MealReminderInsight {
        let enabledSchedules = schedules
            .filter(\.isEnabled)
            .sorted { $0.minuteOfDay < $1.minuteOfDay }

        let patternState = patternState(for: enabledSchedules)
        let recommendation = recommendation(
            for: schedules,
            enabledSchedules: enabledSchedules,
            patternState: patternState
        )

        let nextReminderText = nextReminderText(for: enabledSchedules, now: now)
        let supportingSignals = supportingSignals(
            enabledSchedules: enabledSchedules,
            patternState: patternState,
            nextReminderText: nextReminderText
        )

        let description = description(for: patternState, permissionGranted: permissionGranted)

        return MealReminderInsight(
            headline: description.headline,
            summary: description.summary,
            patternLabel: description.patternLabel,
            patternScore: description.patternScore,
            nextReminderText: nextReminderText,
            controlNote: "Nothing is pushed to reminders or notifications unless you tap the apply button.",
            supportingSignals: supportingSignals,
            recommendation: recommendation
        )
    }

    private func description(
        for patternState: PatternState,
        permissionGranted: Bool
    ) -> (headline: String, summary: String, patternLabel: String, patternScore: Int) {
        if !permissionGranted {
            return (
                headline: "Notification access still needs approval.",
                summary: "The local preview still updates, but reminder delivery will not change silently.",
                patternLabel: "Permission needed",
                patternScore: 36
            )
        }

        switch patternState {
        case .inactive:
            return (
                headline: "No reminder slots are active yet.",
                summary: "The preview can still shape a balanced plan, but nothing will change until you choose it.",
                patternLabel: "Idle",
                patternScore: 10
            )
        case .sparse:
            return (
                headline: "The schedule is a little sparse right now.",
                summary: "A stronger pattern needs a few more active meal slots to keep the day covered.",
                patternLabel: "Sparse",
                patternScore: 45
            )
        case .compressed:
            return (
                headline: "Several reminders are clustered too closely together.",
                summary: "The insight layer suggests spreading the closest meal slots apart before anything is applied.",
                patternLabel: "Compressed",
                patternScore: 62
            )
        case .frontLoaded:
            return (
                headline: "The schedule is front-loaded toward the morning.",
                summary: "The preview suggests giving the later part of the day a little more reminder coverage.",
                patternLabel: "Front-loaded",
                patternScore: 66
            )
        case .backLoaded:
            return (
                headline: "The schedule leans late in the day.",
                summary: "The preview suggests bringing one reminder earlier so the morning has more support.",
                patternLabel: "Back-loaded",
                patternScore: 66
            )
        case .balanced:
            return (
                headline: "Your reminder spacing already looks steady.",
                summary: "The local plan is evenly spread, so the preview keeps the current timing intact.",
                patternLabel: "Balanced",
                patternScore: 88
            )
        }
    }

    private func patternState(for schedules: [MealReminderSchedule]) -> PatternState {
        guard !schedules.isEmpty else {
            return .inactive
        }

        guard schedules.count > 1 else {
            return .sparse
        }

        let minutes = schedules.map(\.minuteOfDay).sorted()
        guard let first = minutes.first, let last = minutes.last else {
            return .inactive
        }

        let gaps = zip(minutes, minutes.dropFirst()).map { $1 - $0 }
        let largestGap = gaps.max() ?? 0
        let smallestGap = gaps.min() ?? 0
        let morningBoundary = 7 * 60 + 30
        let eveningBoundary = 18 * 60 + 30

        if smallestGap < 120 {
            return .compressed
        }

        if first < morningBoundary && last < eveningBoundary {
            return .frontLoaded
        }

        if first > 9 * 60 && last > 20 * 60 {
            return .backLoaded
        }

        if largestGap >= 300 {
            return .sparse
        }

        return .balanced
    }

    private func recommendation(
        for schedules: [MealReminderSchedule],
        enabledSchedules: [MealReminderSchedule],
        patternState: PatternState
    ) -> MealReminderInsight.Recommendation? {
        switch patternState {
        case .inactive:
            return MealReminderInsight.Recommendation(
                title: "Restore a default meal rhythm",
                detail: "The preview can repopulate breakfast, lunch, snack, and dinner as a balanced local draft.",
                reasons: [
                    "No reminder slots are currently active.",
                    "A full day works better when the morning, midday, afternoon, and evening are all covered."
                ],
                proposedSchedules: Self.defaultSchedulePlan(),
                actionTitle: "Apply default rhythm locally"
            )
        case .sparse:
            return MealReminderInsight.Recommendation(
                title: "Fill the missing meal windows",
                detail: "The preview suggests enabling the empty slots so the day has better coverage.",
                reasons: [
                    "One or two reminders leave large parts of the day uncovered.",
                    "Keeping breakfast, lunch, snack, and dinner available makes the pattern easier to follow."
                ],
                proposedSchedules: Self.fillSparseSchedulePlan(from: schedules),
                actionTitle: "Fill missing windows locally"
            )
        case .compressed:
            return MealReminderInsight.Recommendation(
                title: "Spread the closest reminder apart",
                detail: "The preview moves the tightest mid-day slot toward the center of the longest gap.",
                reasons: [
                    "Two or more reminders are too close together.",
                    "A more even spacing makes the afternoon easier to scan at a glance."
                ],
                proposedSchedules: Self.spreadCompressedSchedulePlan(from: schedules, enabledSchedules: enabledSchedules),
                actionTitle: "Preview wider spacing locally"
            )
        case .frontLoaded:
            return MealReminderInsight.Recommendation(
                title: "Give the later day more coverage",
                detail: "The preview nudges one later reminder into the evening so the schedule is less front-heavy.",
                reasons: [
                    "The active reminders are clustered earlier in the day.",
                    "A slightly later slot keeps the schedule from tapering off too soon."
                ],
                proposedSchedules: Self.shiftMorningLoadSchedulePlan(from: schedules, enabledSchedules: enabledSchedules),
                actionTitle: "Preview a later slot locally"
            )
        case .backLoaded:
            return MealReminderInsight.Recommendation(
                title: "Bring one reminder earlier",
                detail: "The preview shifts the first active slot toward the morning so the day starts with more support.",
                reasons: [
                    "The schedule leans late in the day.",
                    "An earlier anchor makes the reminder pattern easier to follow."
                ],
                proposedSchedules: Self.shiftEveningLoadSchedulePlan(from: schedules, enabledSchedules: enabledSchedules),
                actionTitle: "Preview an earlier slot locally"
            )
        case .balanced:
            return nil
        }
    }

    private func nextReminderText(for schedules: [MealReminderSchedule], now: Date) -> String {
        guard !schedules.isEmpty else {
            return "No reminders enabled yet."
        }

        let calendar = Calendar.current
        let upcomingOccurrences = schedules.compactMap { schedule -> (schedule: MealReminderSchedule, date: Date)? in
            let hour = schedule.time.hour ?? 0
            let minute = schedule.time.minute ?? 0
            guard let todayOccurrence = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else {
                return nil
            }

            let occurrence = todayOccurrence >= now
                ? todayOccurrence
                : calendar.date(byAdding: .day, value: 1, to: todayOccurrence) ?? todayOccurrence
            return (schedule, occurrence)
        }
        .sorted { $0.date < $1.date }

        guard let nextOccurrence = upcomingOccurrences.first else {
            return "No reminders enabled yet."
        }

        let dayText: String
        if calendar.isDateInToday(nextOccurrence.date) {
            dayText = "today"
        } else if calendar.isDateInTomorrow(nextOccurrence.date) {
            dayText = "tomorrow"
        } else {
            dayText = nextOccurrence.date.formatted(.dateTime.weekday(.wide))
        }

        return "Next reminder: \(nextOccurrence.schedule.mealType.rawValue.capitalized) at \(nextOccurrence.schedule.displayTime) \(dayText)"
    }

    private func supportingSignals(
        enabledSchedules: [MealReminderSchedule],
        patternState: PatternState,
        nextReminderText: String
    ) -> [String] {
        var signals: [String] = [nextReminderText]

        if enabledSchedules.isEmpty {
            signals.append("No active reminder slots are enabled yet.")
            signals.append("The preview stays local until you choose a schedule.")
            return signals
        }

        let minutes = enabledSchedules.map(\.minuteOfDay).sorted()
        let gapText = gapSummary(for: minutes)
        signals.append(gapText)
        signals.append("Notification changes are never silent here.")

        switch patternState {
        case .inactive:
            break
        case .sparse:
            signals.append("A fuller schedule should cover breakfast, lunch, snack, and dinner.")
        case .compressed:
            signals.append("The closest reminders are clustered too tightly for a calm day flow.")
        case .frontLoaded:
            signals.append("Morning coverage is strong, but the later day could use more support.")
        case .backLoaded:
            signals.append("Evening coverage is strong, but the early day could use more support.")
        case .balanced:
            signals.append("The reminder spacing looks even across the day.")
        }

        return signals
    }

    private func gapSummary(for minutes: [Int]) -> String {
        guard minutes.count > 1 else {
            return "Only one reminder is active, so there is no spacing pattern yet."
        }

        let gaps = zip(minutes, minutes.dropFirst()).map { $1 - $0 }
        let largestGap = gaps.max() ?? 0
        let smallestGap = gaps.min() ?? 0
        return "Spacing ranges from \(Self.format(minutes: smallestGap)) to \(Self.format(minutes: largestGap))."
    }

    private static func defaultSchedulePlan() -> [MealReminderSchedule] {
        [
            MealReminderSchedule(mealType: .breakfast, hour: 8, minute: 0, isEnabled: true),
            MealReminderSchedule(mealType: .lunch, hour: 13, minute: 0, isEnabled: true),
            MealReminderSchedule(mealType: .snack, hour: 16, minute: 0, isEnabled: true),
            MealReminderSchedule(mealType: .dinner, hour: 19, minute: 0, isEnabled: true)
        ]
    }

    private static func fillSparseSchedulePlan(from schedules: [MealReminderSchedule]) -> [MealReminderSchedule] {
        var proposed = schedules
        let template = defaultSchedulePlan()

        for candidate in template {
            if let index = proposed.firstIndex(where: { $0.mealType == candidate.mealType }) {
                proposed[index] = candidate
            } else {
                proposed.append(candidate)
            }
        }

        return proposed.sorted { $0.minuteOfDay < $1.minuteOfDay }
    }

    private static func spreadCompressedSchedulePlan(
        from schedules: [MealReminderSchedule],
        enabledSchedules: [MealReminderSchedule]
    ) -> [MealReminderSchedule] {
        guard enabledSchedules.count > 1 else {
            return schedules
        }

        var proposed = schedules
        let sortedEnabled = enabledSchedules.sorted { $0.minuteOfDay < $1.minuteOfDay }

        if let lunch = sortedEnabled.first(where: { $0.mealType == .lunch }),
           let dinner = sortedEnabled.first(where: { $0.mealType == .dinner }) {
            let midpoint = midpointBetween(lunch, dinner)
            if let snackIndex = proposed.firstIndex(where: { $0.mealType == .snack }) {
                proposed[snackIndex] = proposed[snackIndex].updated(
                    hour: midpoint.hour,
                    minute: midpoint.minute,
                    isEnabled: true
                )
            } else {
                proposed.append(MealReminderSchedule(mealType: .snack, hour: midpoint.hour, minute: midpoint.minute, isEnabled: true))
            }
            return proposed.sorted { $0.minuteOfDay < $1.minuteOfDay }
        }

        guard let first = sortedEnabled.first, let last = sortedEnabled.last else {
            return schedules
        }

        let midpoint = midpointBetween(first, last)
        return shiftMealSlot(
            in: proposed,
            mealType: .snack,
            hour: midpoint.hour,
            minute: midpoint.minute
        )
    }

    private static func shiftMorningLoadSchedulePlan(
        from schedules: [MealReminderSchedule],
        enabledSchedules: [MealReminderSchedule]
    ) -> [MealReminderSchedule] {
        guard enabledSchedules.count > 1 else {
            return schedules
        }

        var proposed = schedules
        let sortedEnabled = enabledSchedules.sorted { $0.minuteOfDay < $1.minuteOfDay }
        guard let lastEnabled = sortedEnabled.last else {
            return proposed
        }

        let target = min(lastEnabled.minuteOfDay + 60, 22 * 60)
        return shiftMealSlot(
            in: proposed,
            mealType: lastEnabled.mealType,
            hour: target / 60,
            minute: target % 60
        )
    }

    private static func shiftEveningLoadSchedulePlan(
        from schedules: [MealReminderSchedule],
        enabledSchedules: [MealReminderSchedule]
    ) -> [MealReminderSchedule] {
        guard enabledSchedules.count > 1 else {
            return schedules
        }

        var proposed = schedules
        let sortedEnabled = enabledSchedules.sorted { $0.minuteOfDay < $1.minuteOfDay }
        guard let firstEnabled = sortedEnabled.first else {
            return proposed
        }

        let target = max(firstEnabled.minuteOfDay - 60, 6 * 60)
        return shiftMealSlot(
            in: proposed,
            mealType: firstEnabled.mealType,
            hour: target / 60,
            minute: target % 60
        )
    }

    private static func shiftMealSlot(
        in schedules: [MealReminderSchedule],
        mealType: MealType,
        hour: Int,
        minute: Int
    ) -> [MealReminderSchedule] {
        var proposed = schedules
        if let index = proposed.firstIndex(where: { $0.mealType == mealType }) {
            proposed[index] = proposed[index].updated(hour: hour, minute: minute, isEnabled: true)
        } else {
            proposed.append(MealReminderSchedule(mealType: mealType, hour: hour, minute: minute, isEnabled: true))
        }

        return proposed.sorted { $0.minuteOfDay < $1.minuteOfDay }
    }

    private static func midpointBetween(
        _ first: MealReminderSchedule,
        _ second: MealReminderSchedule
    ) -> (hour: Int, minute: Int) {
        let midpoint = (first.minuteOfDay + second.minuteOfDay) / 2
        return (hour: midpoint / 60, minute: midpoint % 60)
    }

    private static func format(minutes: Int) -> String {
        let value = max(minutes, 0)
        let hours = value / 60
        let remaining = value % 60

        if hours == 0 {
            return "\(remaining)m"
        }

        if remaining == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remaining)m"
    }

    private enum PatternState {
        case inactive
        case sparse
        case compressed
        case frontLoaded
        case backLoaded
        case balanced
    }
}

@MainActor
final class MealReminderViewModel: ObservableObject {
    @Published var reminderSchedules: [MealReminderSchedule]
    @Published var reminderSummaryText: String
    @Published var reminderPermissionGranted: Bool
    @Published private(set) var insight: MealReminderInsight
    @Published var statusMessage: String?

    private let insightService: any MealReminderInsightService

    init(
        reminderSchedules: [MealReminderSchedule] = [
            MealReminderSchedule(mealType: .breakfast, hour: 8),
            MealReminderSchedule(mealType: .lunch, hour: 13),
            MealReminderSchedule(mealType: .dinner, hour: 19),
            MealReminderSchedule(mealType: .snack, hour: 16)
        ],
        reminderPermissionGranted: Bool = true,
        reminderSummaryText: String? = nil,
        insightService: any MealReminderInsightService = DeterministicMealReminderInsightService(),
        now: Date = .now
    ) {
        self.reminderSchedules = reminderSchedules
        self.reminderPermissionGranted = reminderPermissionGranted
        self.insightService = insightService
        let resolvedInsight = insightService.makeInsight(
            from: reminderSchedules,
            permissionGranted: reminderPermissionGranted,
            now: now
        )
        self.insight = resolvedInsight
        self.reminderSummaryText = reminderSummaryText ?? resolvedInsight.summary
    }

    var status: MealReminderStatus {
        if reminderPermissionGranted {
            return MealReminderStatus(
                title: "Reminders active",
                detail: "Local reminder scheduling is ready for the current meal plan.",
                symbolName: "bell.badge.fill",
                isPositive: true
            )
        } else {
            return MealReminderStatus(
                title: "Permission needed",
                detail: "Reminders are prepared, but notification access still needs to be enabled.",
                symbolName: "bell.slash.fill",
                isPositive: false
            )
        }
    }

    var headline: String {
        insight.headline
    }

    var enabledScheduleCount: Int {
        reminderSchedules.filter(\.isEnabled).count
    }

    var nextReminderText: String {
        insight.nextReminderText
    }

    var scheduleCountText: String {
        "\(enabledScheduleCount)/\(reminderSchedules.count) reminders enabled"
    }

    var patternLabelText: String {
        insight.patternLabel
    }

    var patternScoreText: String {
        "\(insight.patternScore)/100"
    }

    var controlNoteText: String {
        insight.controlNote
    }

    var recommendationTitleText: String {
        insight.recommendation?.title ?? "Your current reminder pattern already looks stable."
    }

    var recommendationDetailText: String {
        insight.recommendation?.detail ?? "No timing changes are suggested right now."
    }

    var recommendationReasons: [String] {
        insight.recommendation?.reasons ?? []
    }

    var recommendationActionTitle: String {
        insight.recommendation?.actionTitle ?? "No update needed"
    }

    var canApplyRecommendation: Bool {
        insight.recommendation != nil
    }

    func toggleReminder(at index: Int) {
        guard reminderSchedules.indices.contains(index) else {
            return
        }

        reminderSchedules[index].isEnabled.toggle()
        statusMessage = nil
        refreshInsight()
    }

    func applyRecommendation() {
        guard let recommendation = insight.recommendation else {
            return
        }

        reminderSchedules = recommendation.proposedSchedules
        statusMessage = "Applied the preview locally. Notification delivery still stays under your control."
        refreshInsight()
    }

    func keepCurrentTimes() {
        statusMessage = "Kept the current reminder times unchanged."
    }

    func refreshInsight(now: Date = .now) {
        insight = insightService.makeInsight(
            from: reminderSchedules,
            permissionGranted: reminderPermissionGranted,
            now: now
        )
        reminderSummaryText = insight.summary
    }
}

private extension MealReminderSchedule {
    var minuteOfDay: Int {
        (time.hour ?? 0) * 60 + (time.minute ?? 0)
    }

    func updated(hour: Int, minute: Int, isEnabled: Bool? = nil) -> MealReminderSchedule {
        MealReminderSchedule(
            mealType: mealType,
            hour: hour,
            minute: minute,
            isEnabled: isEnabled ?? self.isEnabled
        )
    }
}
