import Foundation
import SwiftData

@Model
final class StoredUserProfile {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var displayName: String
    var heightCentimeters: Double
    var currentWeightKilograms: Double
    var goalWeightKilograms: Double
    var goalDate: Date?
    var workoutIntensityRawValue: String
    var workoutDaysData: Data
    var sleepHours: Double?
    var mealCountPerDay: Int
    var preferredMealTimesData: Data
    var heavyMealPreferenceRawValue: String?
    var lightMealPreferenceRawValue: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        displayName: String = "",
        heightCentimeters: Double = 0,
        currentWeightKilograms: Double = 0,
        goalWeightKilograms: Double = 0,
        goalDate: Date? = nil,
        workoutDays: [Weekday] = [],
        workoutIntensityRawValue: String = "",
        sleepHours: Double? = nil,
        mealCountPerDay: Int = 3,
        preferredMealTimes: [MealTimePreference] = [],
        heavyMealPreferenceRawValue: String? = nil,
        lightMealPreferenceRawValue: String? = nil
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
        self.workoutDaysData = Self.encode(workoutDays) ?? Data()
        self.sleepHours = sleepHours
        self.mealCountPerDay = mealCountPerDay
        self.preferredMealTimesData = Self.encode(preferredMealTimes) ?? Data()
        self.heavyMealPreferenceRawValue = heavyMealPreferenceRawValue
        self.lightMealPreferenceRawValue = lightMealPreferenceRawValue
    }

    convenience init(_ profile: UserProfile) {
        self.init(
            id: profile.id,
            createdAt: .now,
            updatedAt: .now,
            displayName: profile.displayName,
            heightCentimeters: profile.heightCentimeters,
            currentWeightKilograms: profile.currentWeightKilograms,
            goalWeightKilograms: profile.goalWeightKilograms,
            goalDate: profile.goalDate,
            workoutDays: profile.workoutDays,
            workoutIntensityRawValue: profile.workoutIntensity.rawValue,
            sleepHours: profile.averageSleepHours,
            mealCountPerDay: profile.mealCount,
            preferredMealTimes: profile.preferredMealTimes,
            heavyMealPreferenceRawValue: profile.heavyMealSlot?.rawValue,
            lightMealPreferenceRawValue: profile.lightMealSlot?.rawValue
        )
    }

    var userProfile: UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            heightCentimeters: heightCentimeters,
            currentWeightKilograms: currentWeightKilograms,
            goalWeightKilograms: goalWeightKilograms,
            goalDate: goalDate,
            workoutDays: Self.decode([Weekday].self, from: workoutDaysData) ?? [],
            workoutIntensity: WorkoutIntensity(rawValue: workoutIntensityRawValue) ?? .moderate,
            averageSleepHours: sleepHours,
            mealCount: mealCountPerDay,
            preferredMealTimes: Self.decode([MealTimePreference].self, from: preferredMealTimesData) ?? [],
            heavyMealSlot: heavyMealPreferenceRawValue.flatMap { MealType(rawValue: $0) },
            lightMealSlot: lightMealPreferenceRawValue.flatMap { MealType(rawValue: $0) }
        )
    }
}

private extension StoredUserProfile {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }
}
