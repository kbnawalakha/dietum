import Foundation

enum AppRoute: Hashable {
    case onboarding
    case mealLogging
    case dashboard

    var title: String {
        switch self {
        case .onboarding:
            return "Setup"
        case .mealLogging:
            return "Log Meal"
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
        case .dashboard:
            return "house.fill"
        }
    }
}
