import Foundation

enum AppRoute: Hashable {
    case onboarding
    case mealLogging
    case weeklyCheckIn
    case dashboard

    var title: String {
        switch self {
        case .onboarding:
            return "Setup"
        case .mealLogging:
            return "Log Meal"
        case .weeklyCheckIn:
            return "Weekly Check-In"
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
        case .dashboard:
            return "house.fill"
        }
    }
}
