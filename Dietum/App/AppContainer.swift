import Foundation
import SwiftData

@MainActor
struct AppContainer {
    static let live = AppContainer()

    private let modelContainer: ModelContainer
    private let mealEntryRepository: any MealEntryRepository
    private let nutritionTargetRepository: any NutritionTargetRepository
    private let weightLogRepository: any WeightLogRepository
    private let userProfileRepository: any UserProfileRepository
    private let progressPhotoRepository: any ProgressPhotoRepository
    private let nutritionAdjustmentRecommendationService: any NutritionAdjustmentRecommendationService

    init(modelContainer: ModelContainer? = nil) {
        let resolvedContainer = modelContainer ?? (try! DietumPersistenceStack.makeContainer())
        self.modelContainer = resolvedContainer
        self.mealEntryRepository = SwiftDataMealEntryRepository(modelContext: resolvedContainer.mainContext)
        self.nutritionTargetRepository = SwiftDataNutritionTargetRepository(modelContext: resolvedContainer.mainContext)
        self.weightLogRepository = SwiftDataWeightEntryRepository(modelContext: resolvedContainer.mainContext)
        self.userProfileRepository = SwiftDataUserProfileRepository(modelContext: resolvedContainer.mainContext)
        self.progressPhotoRepository = SwiftDataProgressPhotoRepository(modelContext: resolvedContainer.mainContext)
        self.nutritionAdjustmentRecommendationService = DeterministicNutritionAdjustmentRecommendationService()
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel()
    }

    func makeWeeklyCheckInViewModel() -> WeeklyCheckInViewModel {
        WeeklyCheckInViewModel(weightLogRepository: weightLogRepository)
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(weightLogRepository: weightLogRepository)
    }

    func makeProgressPhotosViewModel() -> ProgressPhotosViewModel {
        ProgressPhotosViewModel(
            progressPhotoRepository: progressPhotoRepository,
            userProfileRepository: userProfileRepository
        )
    }

    func makeProgressChartsViewModel() -> ProgressChartsViewModel {
        ProgressChartsViewModel(
            weightLogRepository: weightLogRepository,
            recommendationService: nutritionAdjustmentRecommendationService,
            progressPhotoRepository: progressPhotoRepository
        )
    }

    func makeNutritionAdjustmentViewModel() -> NutritionAdjustmentViewModel {
        NutritionAdjustmentViewModel()
    }

    func makeHabitAdherenceView() -> HabitAdherenceView {
        HabitAdherenceView(
            viewModel: HabitAdherenceViewModel(
                mealRepository: mealEntryRepository,
                weightLogRepository: weightLogRepository
            )
        )
    }

    func makeMealLoggingView() -> MealLoggingView {
        MealLoggingView(
            viewModel: MealLoggingViewModel(mealEntryRepository: mealEntryRepository)
        )
    }

    func makeMealHistoryView() -> MealHistoryView {
        MealHistoryView(
            viewModel: MealHistoryViewModel(mealEntryRepository: mealEntryRepository)
        )
    }

    func makeNutritionTrendInsightsView() -> NutritionTrendInsightsView {
        NutritionTrendInsightsView(
            viewModel: NutritionTrendInsightsViewModel(
                mealEntryRepository: mealEntryRepository,
                nutritionTargetRepository: nutritionTargetRepository
            )
        )
    }

    func makeOnboardingView(onComplete: @escaping () -> Void) -> OnboardingView {
        OnboardingView(
            viewModel: OnboardingViewModel(),
            onComplete: onComplete
        )
    }

    func makeGoalSetupView() -> GoalSetupView {
        GoalSetupView(viewModel: GoalSetupViewModel())
    }

    func makeSleepSetupView() -> SleepSetupView {
        SleepSetupView(viewModel: SleepSetupViewModel())
    }

    func makeAccountViewModel() -> AccountViewModel {
        AccountViewModel(
            snapshotProvider: SwiftDataMealExportSnapshotProvider(
                mealEntryRepository: mealEntryRepository
            )
        )
    }

    func makeAccountView(onComplete: @escaping () -> Void) -> AccountView {
        AccountView(viewModel: makeAccountViewModel(), onComplete: onComplete)
    }
}
