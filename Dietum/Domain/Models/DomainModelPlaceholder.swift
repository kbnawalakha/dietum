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

struct NutritionMicronutrients: Codable, Hashable, Sendable {
    var sugarGrams: Double
    var saturatedFatGrams: Double
    var cholesterolMilligrams: Double
    var sodiumMilligrams: Double
    var potassiumMilligrams: Double
    var calciumMilligrams: Double
    var ironMilligrams: Double
    var magnesiumMilligrams: Double
    var phosphorusMilligrams: Double
    var zincMilligrams: Double
    var vitaminAMicrograms: Double
    var vitaminCMilligrams: Double
    var vitaminDMicrograms: Double
    var vitaminEMilligrams: Double
    var vitaminKMicrograms: Double
    var thiaminMilligrams: Double
    var riboflavinMilligrams: Double
    var niacinMilligrams: Double
    var vitaminB6Milligrams: Double
    var folateMicrograms: Double
    var vitaminB12Micrograms: Double
    var cholineMilligrams: Double

    init(
        sugarGrams: Double = 0,
        saturatedFatGrams: Double = 0,
        cholesterolMilligrams: Double = 0,
        sodiumMilligrams: Double = 0,
        potassiumMilligrams: Double = 0,
        calciumMilligrams: Double = 0,
        ironMilligrams: Double = 0,
        magnesiumMilligrams: Double = 0,
        phosphorusMilligrams: Double = 0,
        zincMilligrams: Double = 0,
        vitaminAMicrograms: Double = 0,
        vitaminCMilligrams: Double = 0,
        vitaminDMicrograms: Double = 0,
        vitaminEMilligrams: Double = 0,
        vitaminKMicrograms: Double = 0,
        thiaminMilligrams: Double = 0,
        riboflavinMilligrams: Double = 0,
        niacinMilligrams: Double = 0,
        vitaminB6Milligrams: Double = 0,
        folateMicrograms: Double = 0,
        vitaminB12Micrograms: Double = 0,
        cholineMilligrams: Double = 0
    ) {
        self.sugarGrams = sugarGrams
        self.saturatedFatGrams = saturatedFatGrams
        self.cholesterolMilligrams = cholesterolMilligrams
        self.sodiumMilligrams = sodiumMilligrams
        self.potassiumMilligrams = potassiumMilligrams
        self.calciumMilligrams = calciumMilligrams
        self.ironMilligrams = ironMilligrams
        self.magnesiumMilligrams = magnesiumMilligrams
        self.phosphorusMilligrams = phosphorusMilligrams
        self.zincMilligrams = zincMilligrams
        self.vitaminAMicrograms = vitaminAMicrograms
        self.vitaminCMilligrams = vitaminCMilligrams
        self.vitaminDMicrograms = vitaminDMicrograms
        self.vitaminEMilligrams = vitaminEMilligrams
        self.vitaminKMicrograms = vitaminKMicrograms
        self.thiaminMilligrams = thiaminMilligrams
        self.riboflavinMilligrams = riboflavinMilligrams
        self.niacinMilligrams = niacinMilligrams
        self.vitaminB6Milligrams = vitaminB6Milligrams
        self.folateMicrograms = folateMicrograms
        self.vitaminB12Micrograms = vitaminB12Micrograms
        self.cholineMilligrams = cholineMilligrams
    }

    func scaled(by multiplier: Double) -> NutritionMicronutrients {
        NutritionMicronutrients(
            sugarGrams: sugarGrams * multiplier,
            saturatedFatGrams: saturatedFatGrams * multiplier,
            cholesterolMilligrams: cholesterolMilligrams * multiplier,
            sodiumMilligrams: sodiumMilligrams * multiplier,
            potassiumMilligrams: potassiumMilligrams * multiplier,
            calciumMilligrams: calciumMilligrams * multiplier,
            ironMilligrams: ironMilligrams * multiplier,
            magnesiumMilligrams: magnesiumMilligrams * multiplier,
            phosphorusMilligrams: phosphorusMilligrams * multiplier,
            zincMilligrams: zincMilligrams * multiplier,
            vitaminAMicrograms: vitaminAMicrograms * multiplier,
            vitaminCMilligrams: vitaminCMilligrams * multiplier,
            vitaminDMicrograms: vitaminDMicrograms * multiplier,
            vitaminEMilligrams: vitaminEMilligrams * multiplier,
            vitaminKMicrograms: vitaminKMicrograms * multiplier,
            thiaminMilligrams: thiaminMilligrams * multiplier,
            riboflavinMilligrams: riboflavinMilligrams * multiplier,
            niacinMilligrams: niacinMilligrams * multiplier,
            vitaminB6Milligrams: vitaminB6Milligrams * multiplier,
            folateMicrograms: folateMicrograms * multiplier,
            vitaminB12Micrograms: vitaminB12Micrograms * multiplier,
            cholineMilligrams: cholineMilligrams * multiplier
        )
    }
}

struct NutritionAmounts: Codable, Hashable, Sendable {
    var calories: Int
    var proteinGrams: Double
    var carbohydrateGrams: Double
    var fatGrams: Double
    var fiberGrams: Double
    var micronutrients: NutritionMicronutrients

    init(
        calories: Int = 0,
        proteinGrams: Double = 0,
        carbohydrateGrams: Double = 0,
        fatGrams: Double = 0,
        fiberGrams: Double = 0,
        micronutrients: NutritionMicronutrients = NutritionMicronutrients()
    ) {
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.micronutrients = micronutrients
    }

    private enum CodingKeys: String, CodingKey {
        case calories
        case proteinGrams
        case carbohydrateGrams
        case fatGrams
        case fiberGrams
        case micronutrients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decodeIfPresent(Int.self, forKey: .calories) ?? 0
        proteinGrams = try container.decodeIfPresent(Double.self, forKey: .proteinGrams) ?? 0
        carbohydrateGrams = try container.decodeIfPresent(Double.self, forKey: .carbohydrateGrams) ?? 0
        fatGrams = try container.decodeIfPresent(Double.self, forKey: .fatGrams) ?? 0
        fiberGrams = try container.decodeIfPresent(Double.self, forKey: .fiberGrams) ?? 0
        micronutrients = try container.decodeIfPresent(NutritionMicronutrients.self, forKey: .micronutrients) ?? NutritionMicronutrients()
    }

    func scaled(toGrams grams: Double) -> NutritionAmounts {
        scaled(by: max(0, grams) / 100)
    }

    func scaled(by multiplier: Double) -> NutritionAmounts {
        let multiplier = max(0, multiplier)
        return NutritionAmounts(
            calories: Int((Double(calories) * multiplier).rounded()),
            proteinGrams: proteinGrams * multiplier,
            carbohydrateGrams: carbohydrateGrams * multiplier,
            fatGrams: fatGrams * multiplier,
            fiberGrams: fiberGrams * multiplier,
            micronutrients: micronutrients.scaled(by: multiplier)
        )
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
    var imageData: Data?

    init(
        id: UUID = UUID(),
        storageIdentifier: String,
        capturedAt: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.storageIdentifier = storageIdentifier
        self.capturedAt = capturedAt
        self.imageData = imageData
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
    var bodyFatPercentage: Double?
    var bodyFatBreakdown: BodyFatEstimateBreakdown?

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        angle: ProgressPhotoAngle,
        photo: PhotoMetadata,
        notes: String? = nil,
        bodyFatPercentage: Double? = nil,
        bodyFatBreakdown: BodyFatEstimateBreakdown? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.angle = angle
        self.photo = photo
        self.notes = notes
        self.bodyFatPercentage = bodyFatPercentage
        self.bodyFatBreakdown = bodyFatBreakdown
    }
}

struct BodyFatEstimateBreakdown: Codable, Hashable, Sendable {
    var chestPercentage: Double?
    var armsPercentage: Double?
    var legsPercentage: Double?
    var backPercentage: Double?
    var visceralPercentage: Double?

    var isEmpty: Bool {
        chestPercentage == nil
            && armsPercentage == nil
            && legsPercentage == nil
            && backPercentage == nil
            && visceralPercentage == nil
    }
}
