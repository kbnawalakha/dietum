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
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            viewModel.showMealLogging()
                        } label: {
                            Label(AppRoute.mealLogging.title, systemImage: AppRoute.mealLogging.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showMealReminders()
                        } label: {
                            Label(AppRoute.mealReminders.title, systemImage: AppRoute.mealReminders.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showHabitAdherence()
                        } label: {
                            Label(AppRoute.habitAdherence.title, systemImage: AppRoute.habitAdherence.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showMealExport()
                        } label: {
                            Label(AppRoute.mealExport.title, systemImage: AppRoute.mealExport.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showNutritionInsights()
                        } label: {
                            Label(AppRoute.nutritionInsights.title, systemImage: AppRoute.nutritionInsights.systemImage)
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
                            viewModel.showProgressPhotos()
                        } label: {
                            Label(AppRoute.progressPhotos.title, systemImage: AppRoute.progressPhotos.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showProgressCharts()
                        } label: {
                            Label(AppRoute.progressCharts.title, systemImage: AppRoute.progressCharts.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showNutritionAdjustment()
                        } label: {
                            Label(AppRoute.nutritionAdjustment.title, systemImage: AppRoute.nutritionAdjustment.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showOnboarding()
                        } label: {
                            Label(AppRoute.onboarding.title, systemImage: AppRoute.onboarding.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showGoalSetup()
                        } label: {
                            Label(AppRoute.goalSetup.title, systemImage: AppRoute.goalSetup.systemImage)
                        }
                        .buttonStyle(.appToolbar)

                        Button {
                            viewModel.showSleepSetup()
                        } label: {
                            Label(AppRoute.sleepSetup.title, systemImage: AppRoute.sleepSetup.systemImage)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        container.makeOnboardingView {
                            viewModel.completeOnboarding()
                        }
                    case .goalSetup:
                        container.makeGoalSetupView()
                    case .sleepSetup:
                        container.makeSleepSetupView()
                    case .mealLogging:
                        container.makeMealLoggingView()
                    case .mealReminders:
                        container.makeMealReminderView()
                    case .habitAdherence:
                        container.makeHabitAdherenceView()
                    case .mealExport:
                        container.makeMealExportView()
                    case .nutritionInsights:
                        container.makeNutritionTrendInsightsView()
                    case .weeklyCheckIn:
                        WeeklyCheckInView(viewModel: container.makeWeeklyCheckInViewModel())
                    case .progressPhotos:
                        ProgressPhotosView(viewModel: container.makeProgressPhotosViewModel())
                    case .progressCharts:
                        ProgressChartsView(viewModel: container.makeProgressChartsViewModel())
                    case .nutritionAdjustment:
                        NutritionAdjustmentView(viewModel: container.makeNutritionAdjustmentViewModel())
                    case .dashboard:
                        DashboardView()
                    }
                }
                .fullScreenCover(isPresented: $viewModel.shouldPresentOnboarding) {
                    container.makeOnboardingView {
                        viewModel.completeOnboarding()
                    }
                }
        }
    }
}

final class RootViewModel: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var shouldPresentOnboarding = true

    func showMealLogging() {
        path.append(.mealLogging)
    }

    func showMealReminders() {
        path.append(.mealReminders)
    }

    func showHabitAdherence() {
        path.append(.habitAdherence)
    }

    func showMealExport() {
        path.append(.mealExport)
    }

    func showNutritionInsights() {
        path.append(.nutritionInsights)
    }

    func showWeeklyCheckIn() {
        path.append(.weeklyCheckIn)
    }

    func showProgressPhotos() {
        path.append(.progressPhotos)
    }

    func showProgressCharts() {
        path.append(.progressCharts)
    }

    func showNutritionAdjustment() {
        path.append(.nutritionAdjustment)
    }

    func showOnboarding() {
        path.append(.onboarding)
    }

    func showGoalSetup() {
        path.append(.goalSetup)
    }

    func showSleepSetup() {
        path.append(.sleepSetup)
    }

    func completeOnboarding() {
        shouldPresentOnboarding = false
        path.removeAll()
    }
}
