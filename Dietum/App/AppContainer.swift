import Foundation
import SwiftData

@MainActor
struct AppContainer {
    static let live = AppContainer()

    private let modelContainer: ModelContainer
    private let weightLogRepository: any WeightLogRepository
    private let progressPhotoRepository: any ProgressPhotoRepository

    init(modelContainer: ModelContainer? = nil) {
        let resolvedContainer = modelContainer ?? (try! DietumPersistenceStack.makeContainer())
        self.modelContainer = resolvedContainer
        self.weightLogRepository = SwiftDataWeightEntryRepository(modelContext: resolvedContainer.mainContext)
        self.progressPhotoRepository = SwiftDataProgressPhotoRepository(modelContext: resolvedContainer.mainContext)
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

    func makeNutritionAdjustmentViewModel() -> NutritionAdjustmentViewModel {
        NutritionAdjustmentViewModel()
    }
}
