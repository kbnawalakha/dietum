import Foundation
import SwiftData

@Model
final class StoredUserProfile {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var displayName: String
    var heightCentimeters: Double?
    var currentWeightKilograms: Double?
    var goalWeightKilograms: Double?
    var goalDate: Date?
    var workoutIntensityRawValue: String
    var sleepHours: Double?
    var mealCountPerDay: Int?
    var preferredMealTimesSummary: String
    var heavyMealPreferenceSummary: String
    var lightMealPreferenceSummary: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        displayName: String = "",
        heightCentimeters: Double? = nil,
        currentWeightKilograms: Double? = nil,
        goalWeightKilograms: Double? = nil,
        goalDate: Date? = nil,
        workoutIntensityRawValue: String = "",
        sleepHours: Double? = nil,
        mealCountPerDay: Int? = nil,
        preferredMealTimesSummary: String = "",
        heavyMealPreferenceSummary: String = "",
        lightMealPreferenceSummary: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.displayName = displayName
        self.heightCentimeters = heightCentimeters
        self.currentWeightKilograms = currentWeightKilograms
        self.goalWeightKilograms = goalWeightKilograms
        self.goalDate = goalDate
        self.workoutIntensityRawValue = workoutIntensityRawValue
        self.sleepHours = sleepHours
        self.mealCountPerDay = mealCountPerDay
        self.preferredMealTimesSummary = preferredMealTimesSummary
        self.heavyMealPreferenceSummary = heavyMealPreferenceSummary
        self.lightMealPreferenceSummary = lightMealPreferenceSummary
    }
}
