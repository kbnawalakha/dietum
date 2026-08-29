import Foundation

enum AppRoute: Hashable {
    case onboarding
    case goalSetup
    case sleepSetup
    case mealLogging
    case mealReminders
    case habitAdherence
    case mealExport
    case nutritionInsights
    case weeklyCheckIn
    case progressPhotos
    case progressCharts
    case nutritionAdjustment
    case dashboard

    var title: String {
        switch self {
        case .onboarding:
            return "Setup"
        case .goalSetup:
            return "Goal Setup"
        case .sleepSetup:
            return "Sleep Setup"
        case .mealLogging:
            return "Log Meal"
        case .mealReminders:
            return "Meal Reminders"
        case .habitAdherence:
            return "Habit Streaks"
        case .mealExport:
            return "Export"
        case .nutritionInsights:
            return "Nutrition Insights"
        case .weeklyCheckIn:
            return "Weekly Check-In"
        case .progressPhotos:
            return "Progress Photos"
        case .progressCharts:
            return "Progress Charts"
        case .nutritionAdjustment:
            return "Nutrition Adjustment"
        case .dashboard:
            return "Dashboard"
        }
    }

    var systemImage: String {
        switch self {
        case .onboarding:
            return "sparkles"
        case .goalSetup:
            return "target"
        case .sleepSetup:
            return "bed.double.fill"
        case .mealLogging:
            return "camera.fill"
        case .mealReminders:
            return "bell.fill"
        case .habitAdherence:
            return "chart.line.uptrend.xyaxis"
        case .mealExport:
            return "square.and.arrow.up"
        case .nutritionInsights:
            return "chart.bar.xaxis"
        case .weeklyCheckIn:
            return "calendar.badge.clock"
        case .progressPhotos:
            return "photo.on.rectangle.angled"
        case .progressCharts:
            return "chart.line.uptrend.xyaxis"
        case .nutritionAdjustment:
            return "slider.horizontal.3"
        case .dashboard:
            return "house.fill"
        }
    }
}
