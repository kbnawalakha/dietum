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

    func testReminderInsightKeepsNotificationChangesUserControlled() {
        let service = DeterministicMealReminderInsightService()
        let insight = service.makeInsight(
            from: [
                MealReminderSchedule(mealType: .breakfast, hour: 8),
                MealReminderSchedule(mealType: .dinner, hour: 19)
            ],
            permissionGranted: false,
            now: Self.day(0)
        )

        XCTAssertEqual(insight.patternLabel, "Permission needed")
        XCTAssertEqual(insight.patternScore, 36)
        XCTAssertEqual(insight.headline, "Notification access still needs approval.")
        XCTAssertTrue(insight.controlNote.contains("apply button"))
    }

    func testHabitAdherenceCountsDistinctMealDaysAndCurrentStreak() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let referenceDate = Self.day(0)
        let service = HabitAdherenceService(calendar: calendar)
        let snapshot = HabitAdherenceSnapshot(
            mealEntries: [
                MealEntry(loggedAt: referenceDate, mealType: .breakfast),
                MealEntry(loggedAt: referenceDate, mealType: .dinner),
                MealEntry(loggedAt: Self.day(-1), mealType: .lunch),
                MealEntry(loggedAt: Self.day(-3), mealType: .snack)
            ],
            referenceDate: referenceDate,
            mealWindowDays: 7
        )

        let summary = service.buildSummary(from: snapshot)

        XCTAssertEqual(summary.mealDaysLogged, 3)
        XCTAssertEqual(summary.mealDaysExpected, 7)
        XCTAssertEqual(summary.mealLoggingStreakDays, 2)
        XCTAssertEqual(summary.mealCoveragePercent, 43)
        XCTAssertEqual(summary.latestMealEntryDate, referenceDate)
    }

    func testLocalExportWritesSavedMealEntryPayload() throws {
        let createdAt = Self.day(0)
        let entry = MealEntry(
            loggedAt: createdAt,
            mealType: .dinner,
            notes: "Confirmed locally",
            items: [MealItem(name: "Rice")]
        )
        let snapshot = MealExportSnapshot(
            createdAt: createdAt,
            mealEntries: [MealExportMealEntryPayload(entry: entry)]
        )

        let result = try MealLocalExportService().export(snapshot: snapshot)
        defer { try? FileManager.default.removeItem(at: result.fileURL) }

        let exportedData = try Data(contentsOf: result.fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportedSnapshot = try decoder.decode(MealExportSnapshot.self, from: exportedData)

        XCTAssertEqual(result.byteCount, exportedData.count)
        XCTAssertEqual(exportedSnapshot.mealEntries.count, 1)
        XCTAssertEqual(exportedSnapshot.mealEntries[0].mealTypeRawValue, MealType.dinner.rawValue)
        XCTAssertEqual(exportedSnapshot.mealEntries[0].items[0].name, "Rice")
    }

    private static func day(_ dayOffset: Double) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 + (86_400 * dayOffset))
    }
}
