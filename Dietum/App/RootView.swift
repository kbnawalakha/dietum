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
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showSettings()
                        } label: {
                            Image(systemName: "ellipsis")
                                .accessibilityLabel("Settings")
                        }
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .onboarding:
                        container.makeOnboardingView {
                            viewModel.completeOnboarding()
                        }
                    case .settings:
                        SettingsView(
                            container: container,
                            onAccount: { viewModel.isAccountPresented = true }
                        )
                    case .goalSetup:
                        container.makeGoalSetupView()
                    case .sleepSetup:
                        container.makeSleepSetupView()
                    case .mealLogging:
                        container.makeMealLoggingView()
                    case .mealHistory:
                        container.makeMealHistoryView()
                    case .habitAdherence:
                        container.makeHabitAdherenceView()
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
                .fullScreenCover(isPresented: $viewModel.shouldPresentAccount) {
                    container.makeAccountView {
                        viewModel.completeAccountSetup()
                    }
                }
                .sheet(isPresented: $viewModel.isAccountPresented) {
                    container.makeAccountView {
                        viewModel.isAccountPresented = false
                    }
                }
        }
    }
}

final class RootViewModel: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var shouldPresentOnboarding = true
    @Published var shouldPresentAccount: Bool
    @Published var isAccountPresented = false

    private let profileSetupCompletedKey = "dietum.profile.setup-completed"

    init() {
        let accountSetupCompleted = UserDefaults.standard.bool(forKey: "dietum.account.setup-completed")
        let profileSetupCompleted = UserDefaults.standard.bool(forKey: profileSetupCompletedKey)
        shouldPresentAccount = !accountSetupCompleted
        shouldPresentOnboarding = accountSetupCompleted && !profileSetupCompleted
    }

    func showSettings() {
        path.append(.settings)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: profileSetupCompletedKey)
        shouldPresentOnboarding = false
        path.removeAll()
    }

    func completeAccountSetup() {
        shouldPresentAccount = false
        shouldPresentOnboarding = !UserDefaults.standard.bool(forKey: profileSetupCompletedKey)
    }
}

struct SettingsView: View {
    let container: AppContainer
    let onAccount: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.section) {
                AppHeroCard(
                    eyebrow: "Settings",
                    title: "Keep setup in one place.",
                    message: "Your profile is collected once at launch. Use Settings whenever you want to review or change it."
                )

                settingsSection(
                    title: "Profile",
                    message: "Edit the values that shape your nutrition and sleep context.",
                    routes: [.onboarding, .goalSetup, .sleepSetup]
                )

                settingsSection(
                    title: "Tracking",
                    message: "Open the logging and history flows from this settings hub.",
                    routes: [.weeklyCheckIn]
                )

                settingsSection(
                    title: "History",
                    message: "Review saved meal photos and progress records by date.",
                    routes: [.mealHistory, .progressPhotos, .progressCharts]
                )

                settingsSection(
                    title: "Insights",
                    message: "Review local trends and user-approved recommendations.",
                    routes: [.nutritionInsights, .nutritionAdjustment, .habitAdherence]
                )

                AppSurfaceCard {
                    VStack(alignment: .leading, spacing: AppSpacing.item) {
                        AppSectionHeader(
                            title: "Account and backup",
                            message: "Optional Google Drive backup remains separate from your local profile."
                        )

                        Button(action: onAccount) {
                            Label("Account & Backup", systemImage: "person.crop.circle")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.appToolbar)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.screen)
            .padding(.bottom, AppSpacing.screen * 1.5)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func settingsSection(title: String, message: String, routes: [AppRoute]) -> some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: AppSpacing.item) {
                AppSectionHeader(title: title, message: message)

                ForEach(routes, id: \.self) { route in
                    NavigationLink(value: route) {
                        Label(route.title, systemImage: route.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.appToolbar)
                }
            }
        }
    }
}
