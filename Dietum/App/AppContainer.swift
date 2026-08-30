import Foundation
import SwiftData

@MainActor
struct AppContainer {
    static let live = AppContainer()

    private let modelContainer: ModelContainer
    private let mealEntryRepository: any MealEntryRepository
    private let weightLogRepository: any WeightLogRepository
    private let progressPhotoRepository: any ProgressPhotoRepository
    private let nutritionAdjustmentRecommendationService: any NutritionAdjustmentRecommendationService

    init(modelContainer: ModelContainer? = nil) {
        let resolvedContainer = modelContainer ?? (try! DietumPersistenceStack.makeContainer())
        self.modelContainer = resolvedContainer
        self.mealEntryRepository = SwiftDataMealEntryRepository(modelContext: resolvedContainer.mainContext)
        self.weightLogRepository = SwiftDataWeightEntryRepository(modelContext: resolvedContainer.mainContext)
        self.progressPhotoRepository = SwiftDataProgressPhotoRepository(modelContext: resolvedContainer.mainContext)
        self.nutritionAdjustmentRecommendationService = DeterministicNutritionAdjustmentRecommendationService()
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel()
    }

    func makeWeeklyCheckInViewModel() -> WeeklyCheckInViewModel {
        WeeklyCheckInViewModel(weightLogRepository: weightLogRepository)
    }

    func makeProgressPhotosViewModel() -> ProgressPhotosViewModel {
        ProgressPhotosViewModel(progressPhotoRepository: progressPhotoRepository)
    }

    func makeProgressChartsViewModel() -> ProgressChartsViewModel {
        ProgressChartsViewModel(
            weightLogRepository: weightLogRepository,
            recommendationService: nutritionAdjustmentRecommendationService
        )
    }

    func makeNutritionAdjustmentViewModel() -> NutritionAdjustmentViewModel {
        NutritionAdjustmentViewModel()
    }

    func makeMealReminderView() -> MealReminderView {
        MealReminderView()
    }

    func makeHabitAdherenceView() -> HabitAdherenceView {
        HabitAdherenceView(
            viewModel: HabitAdherenceViewModel(
                mealRepository: mealEntryRepository,
                weightLogRepository: weightLogRepository
            )
        )
    }

    func makeMealExportView() -> MealExportView {
        MealExportView(
            viewModel: MealExportViewModel(
                snapshotProvider: SwiftDataMealExportSnapshotProvider(
                    mealEntryRepository: mealEntryRepository
                )
            )
        )
    }

    func makeMealLoggingView() -> MealLoggingView {
        MealLoggingView(
            viewModel: MealLoggingViewModel(mealEntryRepository: mealEntryRepository)
        )
    }

    func makeNutritionTrendInsightsView() -> NutritionTrendInsightsView {
        NutritionTrendInsightsView(
            viewModel: NutritionTrendInsightsViewModel(
                mealEntryRepository: mealEntryRepository
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
}
