import Foundation

struct HabitAdherenceSnapshot: Sendable, Hashable {
    var mealEntries: [MealEntry]
    var weightLogs: [WeightLog]
    var referenceDate: Date
    var mealWindowDays: Int
    var checkInWindowDays: Int

    init(
        mealEntries: [MealEntry] = [],
        weightLogs: [WeightLog] = [],
        referenceDate: Date = Date(),
        mealWindowDays: Int = 7,
        checkInWindowDays: Int = 28
    ) {
        self.mealEntries = mealEntries
        self.weightLogs = weightLogs
        self.referenceDate = referenceDate
        self.mealWindowDays = mealWindowDays
        self.checkInWindowDays = checkInWindowDays
    }
}

struct HabitAdherenceSummary: Sendable, Hashable {
    var mealLoggingStreakDays: Int
    var checkInStreakDays: Int
    var mealCoverageRatio: Double
    var checkInCoverageRatio: Double
    var mealDaysLogged: Int
    var mealDaysExpected: Int
    var checkInWeeksLogged: Int
    var checkInWeeksExpected: Int
    var latestMealEntryDate: Date?
    var latestCheckInDate: Date?

    var mealCoveragePercent: Int {
        Int((mealCoverageRatio * 100).rounded())
    }

    var checkInCoveragePercent: Int {
        Int((checkInCoverageRatio * 100).rounded())
    }
}

struct HabitSummaryCard: Identifiable, Sendable, Hashable {
    enum Kind: Sendable, Hashable {
        case streak
        case coverage
        case consistency
    }

    var id: Kind { kind }
    var kind: Kind
    var title: String
    var value: String
    var detail: String
}

enum HabitAdherenceLoadingState: Sendable, Hashable {
    case idle
    case loading
    case loaded(HabitAdherenceSummary)
    case empty
    case failed(message: String)
}
