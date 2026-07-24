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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.showMealLogging()
                        } label: {
                            Label(AppRoute.mealLogging.title, systemImage: AppRoute.mealLogging.systemImage)
                        }
                        .buttonStyle(.appToolbar)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showOnboarding()
                        } label: {
                            Label(AppRoute.onboarding.title, systemImage: AppRoute.onboarding.systemImage)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        OnboardingView()
                    case .mealLogging:
                        MealLoggingView()
                    case .dashboard:
                        DashboardView()
                    }
                }
        }
    }
}

final class RootViewModel: ObservableObject {
    @Published var path: [AppRoute] = []

    func showMealLogging() {
        path.append(.mealLogging)
    }

    func showOnboarding() {
        path.append(.onboarding)
    }
}
