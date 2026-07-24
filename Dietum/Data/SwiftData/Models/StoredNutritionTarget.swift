import Foundation
import SwiftData

@Model
final class StoredNutritionTarget {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var effectiveDate: Date
    var isActive: Bool

    var calorieTarget: Int
    var proteinTargetGrams: Double
    var carbohydrateTargetGrams: Double
    var fatTargetGrams: Double
    var fiberTargetGrams: Double

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        effectiveDate: Date = .now,
        isActive: Bool = true,
        calorieTarget: Int = 0,
        proteinTargetGrams: Double = 0,
        carbohydrateTargetGrams: Double = 0,
        fatTargetGrams: Double = 0,
        fiberTargetGrams: Double = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.effectiveDate = effectiveDate
        self.isActive = isActive
        self.calorieTarget = calorieTarget
        self.proteinTargetGrams = proteinTargetGrams
        self.carbohydrateTargetGrams = carbohydrateTargetGrams
        self.fatTargetGrams = fatTargetGrams
        self.fiberTargetGrams = fiberTargetGrams
    }
}
