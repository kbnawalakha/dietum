import Foundation

enum AppRoute: Hashable {
    case onboarding
    case dashboard
}

extension AppRoute {
    var title: String {
        switch self {
        case .onboarding:
            return "Setup"
        case .dashboard:
            return "Dashboard"
        }
    }

    var systemImageName: String {
        switch self {
        case .onboarding:
            return "person.crop.square"
        case .dashboard:
            return "rectangle.grid.2x2"
        }
    }
}
