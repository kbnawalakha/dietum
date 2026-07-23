import SwiftUI

struct RootView: View {
    @StateObject private var viewModel: RootViewModel

    init(viewModel: RootViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            DashboardView()
                .navigationTitle("Dietum")
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        OnboardingView()
                    case .dashboard:
                        DashboardView()
                    }
                }
        }
    }
}

final class RootViewModel: ObservableObject {
    @Published var path: [AppRoute] = []

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }
}

