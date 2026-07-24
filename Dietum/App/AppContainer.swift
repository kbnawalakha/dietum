import Foundation
import SwiftData

@MainActor
struct AppContainer {
    static let live = AppContainer()

    private let modelContainer: ModelContainer
    private let weightLogRepository: any WeightLogRepository

    init(modelContainer: ModelContainer? = nil) {
        let resolvedContainer = modelContainer ?? (try! DietumPersistenceStack.makeContainer())
        self.modelContainer = resolvedContainer
        self.weightLogRepository = SwiftDataWeightEntryRepository(modelContext: resolvedContainer.mainContext)
    }

    func makeRootViewModel() -> RootViewModel {
        RootViewModel()
    }

    func makeWeeklyCheckInViewModel() -> WeeklyCheckInViewModel {
        WeeklyCheckInViewModel(weightLogRepository: weightLogRepository)
    }
}
