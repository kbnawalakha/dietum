import Foundation

enum NutritionTrendDirection: String, Codable, CaseIterable, Hashable, Sendable {
    case cut
    case maintain
    case increase
}

struct NutritionTrendAnalysisInput: Codable, Hashable, Sendable {
    var currentNutritionTarget: NutritionTarget
    var recentWeightLogs: [WeightLog]
    var goalWeightKilograms: Double?
    var goalDate: Date?
    var recentAverageCalories: Int?

    init(
        currentNutritionTarget: NutritionTarget,
        recentWeightLogs: [WeightLog] = [],
        goalWeightKilograms: Double? = nil,
        goalDate: Date? = nil,
        recentAverageCalories: Int? = nil
    ) {
        self.currentNutritionTarget = currentNutritionTarget
        self.recentWeightLogs = recentWeightLogs
        self.goalWeightKilograms = goalWeightKilograms
        self.goalDate = goalDate
        self.recentAverageCalories = recentAverageCalories
    }
}

struct NutritionTrendAnalysisOutput: Codable, Hashable, Sendable {
    var averageWeeklyWeightChangeKilograms: Double
    var totalWeightChangeKilograms: Double
    var trendDirection: NutritionTrendDirection
    var summary: String
    var supportingSignals: [String]

    init(
        averageWeeklyWeightChangeKilograms: Double,
        totalWeightChangeKilograms: Double,
        trendDirection: NutritionTrendDirection,
        summary: String,
        supportingSignals: [String] = []
    ) {
        self.averageWeeklyWeightChangeKilograms = averageWeeklyWeightChangeKilograms
        self.totalWeightChangeKilograms = totalWeightChangeKilograms
        self.trendDirection = trendDirection
        self.summary = summary
        self.supportingSignals = supportingSignals
    }
}

struct CalorieAdjustmentRecommendation: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var generatedAt: Date
    var currentDailyCalories: Int
    var suggestedDailyCalories: Int
    var calorieDelta: Int
    var reasonSummary: String
    var expectedEffect: String
    var supportingReasons: [String]
    var trendAnalysis: NutritionTrendAnalysisOutput
    var requiresApproval: Bool

    init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        currentDailyCalories: Int,
        suggestedDailyCalories: Int,
        calorieDelta: Int,
        reasonSummary: String,
        expectedEffect: String,
        supportingReasons: [String] = [],
        trendAnalysis: NutritionTrendAnalysisOutput,
        requiresApproval: Bool = true
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.currentDailyCalories = currentDailyCalories
        self.suggestedDailyCalories = suggestedDailyCalories
        self.calorieDelta = calorieDelta
        self.reasonSummary = reasonSummary
        self.expectedEffect = expectedEffect
        self.supportingReasons = supportingReasons
        self.trendAnalysis = trendAnalysis
        self.requiresApproval = requiresApproval
    }
}

