import Foundation

enum AppRoute: Hashable {
    case onboarding
    case mealLogging
    case weeklyCheckIn
    case progressPhotos
    case progressCharts
    case nutritionAdjustment
    case dashboard

    var title: String {
        switch self {
        case .onboarding:
            return "Setup"
        case .mealLogging:
            return "Log Meal"
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
        case .mealLogging:
            return "camera.fill"
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
