import Foundation
import SwiftUI

struct DashboardStatCard: Identifiable, Hashable, Sendable {
    var id = UUID()
    var title: String
    var value: String
    var detail: String
    var symbolName: String
}

struct DashboardActionItem: Identifiable, Hashable, Sendable {
    var id = UUID()
    var title: String
    var symbolName: String
    var route: AppRoute
}

struct DashboardReadinessItem: Identifiable, Hashable, Sendable {
    var id = UUID()
    var title: String
    var detail: String
    var isComplete: Bool
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var todayCaloriesTarget: Int
    @Published var plannedMeals: Int
    @Published var sleepHoursGoal: Double
    @Published var latestWeightKilograms: Double?
    @Published var latestWeightChangeKilograms: Double?
    @Published var recommendedCalories: Int?
    @Published var progressPhotosCount: Int
    @Published var latestPhotoAngle: ProgressPhotoAngle?
    @Published var reminderStatusText: String
    @Published var readinessItems: [DashboardReadinessItem]

    let quickActions: [DashboardActionItem] = [
        DashboardActionItem(title: "Log a meal", symbolName: "camera.fill", route: .mealLogging),
        DashboardActionItem(title: "Meal reminders", symbolName: "bell.fill", route: .mealReminders),
        DashboardActionItem(title: "Review habit streaks", symbolName: "chart.line.uptrend.xyaxis", route: .habitAdherence),
        DashboardActionItem(title: "Export local data", symbolName: "square.and.arrow.up", route: .mealExport),
        DashboardActionItem(title: "Start weekly check-in", symbolName: "calendar.badge.clock", route: .weeklyCheckIn),
        DashboardActionItem(title: "Open progress photos", symbolName: "photo.on.rectangle.angled", route: .progressPhotos),
        DashboardActionItem(title: "Open progress charts", symbolName: "chart.line.uptrend.xyaxis", route: .progressCharts),
        DashboardActionItem(title: "Review calorie adjustment", symbolName: "slider.horizontal.3", route: .nutritionAdjustment),
        DashboardActionItem(title: "Open onboarding", symbolName: "arrow.right.circle.fill", route: .onboarding)
    ]

    init(
        todayCaloriesTarget: Int = 2_400,
        plannedMeals: Int = 4,
        sleepHoursGoal: Double = 7.5,
        latestWeightKilograms: Double? = 72.4,
        latestWeightChangeKilograms: Double? = -0.3,
        recommendedCalories: Int? = 2_300,
        progressPhotosCount: Int = 12,
        latestPhotoAngle: ProgressPhotoAngle? = .front,
        reminderStatusText: String = "Meal reminder scheduled for lunchtime.",
        readinessItems: [DashboardReadinessItem] = [
            DashboardReadinessItem(title: "Meal logging ready", detail: "Quick actions are available from the dashboard.", isComplete: true),
            DashboardReadinessItem(title: "Weekly check-in ready", detail: "A weight update can be logged from the next card.", isComplete: true),
            DashboardReadinessItem(title: "Goal review ready", detail: "The latest calorie recommendation is available for approval.", isComplete: true),
            DashboardReadinessItem(title: "Photo tracking ready", detail: "Progress photo history is stored locally.", isComplete: true)
        ]
    ) {
        self.todayCaloriesTarget = todayCaloriesTarget
        self.plannedMeals = plannedMeals
        self.sleepHoursGoal = sleepHoursGoal
        self.latestWeightKilograms = latestWeightKilograms
        self.latestWeightChangeKilograms = latestWeightChangeKilograms
        self.recommendedCalories = recommendedCalories
        self.progressPhotosCount = progressPhotosCount
        self.latestPhotoAngle = latestPhotoAngle
        self.reminderStatusText = reminderStatusText
        self.readinessItems = readinessItems
    }

    var headline: String {
        "Track meals, weight, and progress without leaving the flow of the app."
    }

    var todaySummaryText: String {
        "A quick scan of targets, reminders, and next actions for today."
    }

    var progressHeadline: String {
        "Look at weight and nutrition together instead of reading them in isolation."
    }

    var photosHeadline: String {
        "Track front, back, left, and right images over time."
    }

    var nutritionHeadline: String {
        "Preview a calorie change and require approval before it is applied."
    }

    var targetCards: [DashboardStatCard] {
        [
            DashboardStatCard(
                title: "Calories",
                value: "\(todayCaloriesTarget)",
                detail: "Target for today",
                symbolName: "flame.fill"
            ),
            DashboardStatCard(
                title: "Meals",
                value: "\(plannedMeals)",
                detail: "Planned today",
                symbolName: "fork.knife"
            ),
            DashboardStatCard(
                title: "Sleep",
                value: String(format: "%.1f h", sleepHoursGoal),
                detail: "Goal range",
                symbolName: "bed.double.fill"
            )
        ]
    }

    var trendCards: [DashboardStatCard] {
        [
            DashboardStatCard(
                title: "Latest weight",
                value: latestWeightKilograms.map { String(format: "%.1f kg", $0) } ?? "—",
                detail: "From the most recent check-in",
                symbolName: "scalemass"
            ),
            DashboardStatCard(
                title: "Calories",
                value: recommendedCalories.map(String.init) ?? "—",
                detail: "Recommended target",
                symbolName: "flame.fill"
            ),
            DashboardStatCard(
                title: "Trend",
                value: latestWeightChangeKilograms.map { String(format: "%+.1f kg", $0) } ?? "—",
                detail: "Over the last 7 days",
                symbolName: "chart.line.uptrend.xyaxis"
            )
        ]
    }

    var photoCards: [DashboardStatCard] {
        [
            DashboardStatCard(
                title: "Photos",
                value: "\(progressPhotosCount)",
                detail: "Stored locally",
                symbolName: "photo.on.rectangle.angled"
            ),
            DashboardStatCard(
                title: "Latest angle",
                value: latestPhotoAngle?.dashboardLabel ?? "—",
                detail: "Captured today",
                symbolName: "camera.viewfinder"
            )
        ]
    }

    var nutritionCards: [DashboardStatCard] {
        [
            DashboardStatCard(
                title: "Current target",
                value: "\(todayCaloriesTarget)",
                detail: "kcal per day",
                symbolName: "flame.fill"
            ),
            DashboardStatCard(
                title: "Suggested",
                value: recommendedCalories.map(String.init) ?? "—",
                detail: "kcal per day",
                symbolName: "slider.horizontal.3"
            )
        ]
    }

    var readinessSummaryText: String {
        let completeCount = readinessItems.filter(\.isComplete).count
        return "\(completeCount) of \(readinessItems.count) dashboard checks are ready."
    }

    var readinessDetailText: String {
        readinessItems.allSatisfy(\.isComplete)
            ? "Everything needed for a quick daily review is available locally."
            : "Some parts of the daily review still need attention."
    }
}

private extension ProgressPhotoAngle {
    var dashboardLabel: String {
        switch self {
        case .front:
            return "Front"
        case .back:
            return "Back"
        case .left:
            return "Left"
        case .right:
            return "Right"
        }
    }
}
