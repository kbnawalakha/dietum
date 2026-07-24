import SwiftUI

struct RootView: View {
    let container: AppContainer
    @StateObject private var viewModel: RootViewModel

    init(container: AppContainer, viewModel: RootViewModel) {
        self.container = container
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

                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            viewModel.showWeeklyCheckIn()
                        } label: {
                            Label(AppRoute.weeklyCheckIn.title, systemImage: AppRoute.weeklyCheckIn.systemImage)
                        }
                        .buttonStyle(.appToolbar)

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
                    case .weeklyCheckIn:
                        WeeklyCheckInView(viewModel: container.makeWeeklyCheckInViewModel())
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

    func showWeeklyCheckIn() {
        path.append(.weeklyCheckIn)
    }

    func showOnboarding() {
        path.append(.onboarding)
    }
}
