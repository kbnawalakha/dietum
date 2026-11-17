import Foundation
import SwiftData

@MainActor
final class SwiftDataNutritionTargetRepository: NutritionTargetRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchActiveTarget() throws -> StoredNutritionTarget? {
        let targets = try modelContext.fetch(FetchDescriptor<StoredNutritionTarget>())
        return targets.first(where: { $0.isActive })
    }

    func fetchActiveNutritionTarget() async throws -> NutritionTarget? {
        guard let target = try fetchActiveTarget() else {
            return nil
        }

        return NutritionTarget(
            id: target.id,
            dailyGoal: NutritionAmounts(
                calories: target.calorieTarget,
                proteinGrams: target.proteinTargetGrams,
                carbohydrateGrams: target.carbohydrateTargetGrams,
                fatGrams: target.fatTargetGrams,
                fiberGrams: target.fiberTargetGrams
            ),
            updatedAt: target.updatedAt,
            isActive: target.isActive
        )
    }

    func replaceActiveTarget(_ target: StoredNutritionTarget) throws {
        let existingTargets = try modelContext.fetch(FetchDescriptor<StoredNutritionTarget>())
        existingTargets.forEach { modelContext.delete($0) }

        target.isActive = true
        modelContext.insert(target)
        try modelContext.save()
    }
}
