import Foundation

enum WorkoutIntensity: String, Codable, CaseIterable, Hashable, Sendable {
    case low
    case moderate
    case high
}

enum Weekday: String, Codable, CaseIterable, Hashable, Sendable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

enum MealType: String, Codable, CaseIterable, Hashable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack
    case custom
}

enum ProgressPhotoAngle: String, Codable, CaseIterable, Hashable, Sendable {
    case front
    case back
    case left
    case right
}

struct NutritionAmounts: Codable, Hashable, Sendable {
    var calories: Int
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var fiberGrams: Double

    init(
        calories: Int = 0,
        proteinGrams: Double = 0,
        carbohydrateGrams: Double = 0,
        fatGrams: Double = 0,
        fiberGrams: Double = 0
    ) {
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
    }
}

struct MealTimePreference: Codable, Hashable, Sendable {
    var mealType: MealType
    var hour: Int
    var minute: Int

    init(mealType: MealType, hour: Int, minute: Int = 0) {
        self.mealType = mealType
        self.hour = hour
        self.minute = minute
    }
}

struct UserProfile: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var displayName: String
    var heightCentimeters: Double
    var currentWeightKilograms: Double
    var goalWeightKilograms: Double
    var goalDate: Date?
    var workoutDays: [Weekday]
    var workoutIntensity: WorkoutIntensity
    var averageSleepHours: Double?
    var mealCount: Int
    var preferredMealTimes: [MealTimePreference]
    var heavyMealSlot: MealType?
    var lightMealSlot: MealType?

    init(
        id: UUID = UUID(),
        displayName: String,
        heightCentimeters: Double,
        currentWeightKilograms: Double,
        goalWeightKilograms: Double,
        goalDate: Date? = nil,
        workoutDays: [Weekday] = [],
        workoutIntensity: WorkoutIntensity = .moderate,
        averageSleepHours: Double? = nil,
        mealCount: Int = 3,
        preferredMealTimes: [MealTimePreference] = [],
        heavyMealSlot: MealType? = nil,
        lightMealSlot: MealType? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.heightCentimeters = heightCentimeters
        self.currentWeightKilograms = currentWeightKilograms
        self.goalWeightKilograms = goalWeightKilograms
        self.goalDate = goalDate
        self.workoutDays = workoutDays
        self.workoutIntensity = workoutIntensity
        self.averageSleepHours = averageSleepHours
        self.mealCount = mealCount
        self.preferredMealTimes = preferredMealTimes
        self.heavyMealSlot = heavyMealSlot
        self.lightMealSlot = lightMealSlot
    }
}

struct NutritionTarget: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var dailyGoal: NutritionAmounts
    var updatedAt: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        dailyGoal: NutritionAmounts,
        updatedAt: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = id
        self.dailyGoal = dailyGoal
        self.updatedAt = updatedAt
        self.isActive = isActive
    }
}

struct PhotoMetadata: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var storageIdentifier: String
    var capturedAt: Date

    init(
        id: UUID = UUID(),
        storageIdentifier: String,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.storageIdentifier = storageIdentifier
        self.capturedAt = capturedAt
    }
}

struct MealItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var quantity: Double?
    var unit: String?
    var nutrition: NutritionAmounts

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Double? = nil,
        unit: String? = nil,
        nutrition: NutritionAmounts = NutritionAmounts()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.nutrition = nutrition
    }
}

struct MealEntry: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var loggedAt: Date
    var mealType: MealType
    var title: String?
    var notes: String?
    var photoMetadata: PhotoMetadata?
    var items: [MealItem]
    var nutrition: NutritionAmounts

    init(
        id: UUID = UUID(),
        loggedAt: Date = Date(),
        mealType: MealType,
        title: String? = nil,
        notes: String? = nil,
        photoMetadata: PhotoMetadata? = nil,
        items: [MealItem] = [],
        nutrition: NutritionAmounts = NutritionAmounts()
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.mealType = mealType
        self.title = title
        self.notes = notes
        self.photoMetadata = photoMetadata
        self.items = items
        self.nutrition = nutrition
    }
}

struct WeightLog: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var recordedAt: Date
    var weightKilograms: Double
    var notes: String?

    init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        weightKilograms: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.weightKilograms = weightKilograms
        self.notes = notes
    }
}

struct ProgressPhotoMetadata: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var capturedAt: Date
    var angle: ProgressPhotoAngle
    var photo: PhotoMetadata
    var notes: String?

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        angle: ProgressPhotoAngle,
        photo: PhotoMetadata,
        notes: String? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.angle = angle
        self.photo = photo
        self.notes = notes
    }
}
