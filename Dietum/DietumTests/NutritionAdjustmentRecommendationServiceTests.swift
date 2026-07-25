import XCTest
@testable import Dietum

final class NutritionAdjustmentRecommendationServiceTests: XCTestCase {
    private let service = DeterministicNutritionAdjustmentRecommendationService()

    func testAnalyzeTrendSortsWeightLogsAndClassifiesDownwardTrend() async throws {
        let input = NutritionTrendAnalysisInput(
            currentNutritionTarget: NutritionTarget(dailyGoal: NutritionAmounts(calories: 2200)),
            recentWeightLogs: [
                WeightLog(recordedAt: Self.day(14), weightKilograms: 89.4),
                WeightLog(recordedAt: Self.day(0), weightKilograms: 92.0),
                WeightLog(recordedAt: Self.day(7), weightKilograms: 90.7)
            ]
        )

        let analysis = try await service.analyzeTrend(from: input)

        XCTAssertEqual(analysis.averageWeeklyWeightChangeKilograms, -1.3, accuracy: 0.0001)
        XCTAssertEqual(analysis.totalWeightChangeKilograms, -2.6, accuracy: 0.0001)
        XCTAssertEqual(analysis.trendDirection, .cut)
        XCTAssertEqual(analysis.summary, "Weight is trending down at a steady pace.")
        XCTAssertEqual(
            analysis.supportingSignals,
            [
                "Tracked 3 weight entries across about 2.0 week(s).",
                "Latest weight is 89.4 kg."
            ]
        )
    }

    func testRecommendAdjustmentReturnsNeutralRecommendationWithoutGoalContext() async throws {
        let input = NutritionTrendAnalysisInput(
            currentNutritionTarget: NutritionTarget(dailyGoal: NutritionAmounts(calories: 2350)),
            recentWeightLogs: [
                WeightLog(recordedAt: Self.day(0), weightKilograms: 88.5),
                WeightLog(recordedAt: Self.day(7), weightKilograms: 88.2)
            ]
        )

        let recommendation = try await service.recommendAdjustment(from: input)

        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.currentDailyCalories, 2350)
        XCTAssertEqual(recommendation?.suggestedDailyCalories, 2350)
        XCTAssertEqual(recommendation?.calorieDelta, 0)
        XCTAssertEqual(
            recommendation?.reasonSummary,
            "Keep the current target until the goal context is filled in."
        )
        XCTAssertEqual(
            recommendation?.expectedEffect,
            "No change to the calorie target yet."
        )
        XCTAssertEqual(
            recommendation?.supportingReasons,
            [
                "Tracked 2 weight entries across about 1.0 week(s).",
                "Latest weight is 88.2 kg."
            ]
        )
        XCTAssertEqual(recommendation?.trendAnalysis.trendDirection, .cut)
    }

    private static func day(_ dayOffset: Double) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 + (86_400 * dayOffset))
    }
}
