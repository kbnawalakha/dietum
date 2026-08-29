import Foundation

struct NutritionTrendInsightsInput: Sendable {
    let mealEntries: [MealEntry]
    let referenceDate: Date
    let target: NutritionAmounts?
    let windowDays: Int

    init(
        mealEntries: [MealEntry],
        referenceDate: Date = .now,
        target: NutritionAmounts? = nil,
        windowDays: Int = 7
    ) {
        self.mealEntries = mealEntries
        self.referenceDate = referenceDate
        self.target = target
        self.windowDays = max(1, windowDays)
    }
}

struct NutritionTrendInsights: Hashable, Sendable {
    struct DailyPoint: Identifiable, Hashable, Sendable {
        let date: Date
        let calories: Double
        let proteinGrams: Double
        let carbohydrateGrams: Double
        let fatGrams: Double
        let fiberGrams: Double

        var id: Date { date }
    }

    enum Direction: String, Hashable, Sendable {
        case rising
        case falling
        case steady
    }

    let recentAverageCalories: Double
    let previousAverageCalories: Double?
    let calorieDirection: Direction
    let recentAverageProteinGrams: Double
    let recentAverageCarbohydrateGrams: Double
    let recentAverageFatGrams: Double
    let recentAverageFiberGrams: Double
    let loggedDays: Int
    let expectedDays: Int
    let dailyPoints: [DailyPoint]
    let target: NutritionAmounts?

    var coverage: Double {
        guard expectedDays > 0 else { return 0 }
        return min(1, Double(loggedDays) / Double(expectedDays))
    }

    var isEstimate: Bool {
        loggedDays < expectedDays
    }

    var sampleDescription: String {
        "Based on \(loggedDays) of \(expectedDays) days logged"
    }
}

enum NutritionTrendInsightsState: Equatable {
    case idle
    case loading
    case loaded(NutritionTrendInsights)
    case empty
    case failed(message: String)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.empty, .empty):
            return true
        case let (.loaded(left), .loaded(right)):
            return left == right
        case let (.failed(left), .failed(right)):
            return left == right
        default:
            return false
        }
    }
}
