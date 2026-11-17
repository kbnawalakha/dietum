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

    func testOAuthPlaceholderConfigurationStaysDisabledUntilConfigured() {
        let configuration = GoogleDriveConfiguration(info: [
            "GoogleOAuthClientID": "$(GOOGLE_OAUTH_CLIENT_ID)",
            "GoogleOAuthRedirectURI": "$(GOOGLE_OAUTH_REDIRECT_URI)"
        ])

        XCTAssertFalse(configuration.isConfigured)
    }

    func testOnboardingWorkoutDayToggleDeselectsOnSecondActivation() {
        var draft = OnboardingDraft()

        draft.toggleWorkoutDay(.monday)
        XCTAssertTrue(draft.workoutDays.contains(.monday))

        draft.toggleWorkoutDay(.monday)
        XCTAssertFalse(draft.workoutDays.contains(.monday))
    }

    func testOnboardingNutritionBreakdownCalculatesMacroPercentagesAndFiberFromCarbs() {
        var draft = OnboardingDraft()
        draft.dailyCalories = "2000"
        draft.proteinPercentage = "20"
        draft.carbohydratePercentage = "50"
        draft.fatPercentage = "30"
        draft.fiberPercentage = "10"

        let breakdown = draft.nutritionBreakdown

        XCTAssertEqual(breakdown.proteinCalories ?? 0, 400, accuracy: 0.001)
        XCTAssertEqual(breakdown.carbohydrateCalories ?? 0, 1000, accuracy: 0.001)
        XCTAssertEqual(breakdown.fatCalories ?? 0, 600, accuracy: 0.001)
        XCTAssertEqual(breakdown.proteinPercentage ?? 0, 20, accuracy: 0.001)
        XCTAssertEqual(breakdown.carbohydratePercentage ?? 0, 50, accuracy: 0.001)
        XCTAssertEqual(breakdown.fatPercentage ?? 0, 30, accuracy: 0.001)
        XCTAssertEqual(breakdown.proteinGrams ?? 0, 100, accuracy: 0.001)
        XCTAssertEqual(breakdown.carbohydrateGrams ?? 0, 250, accuracy: 0.001)
        XCTAssertEqual(breakdown.fatGrams ?? 0, 66.6667, accuracy: 0.001)
        XCTAssertEqual(breakdown.fiberPercentage ?? 0, 10, accuracy: 0.001)
        XCTAssertEqual(breakdown.fiberGrams ?? 0, 25, accuracy: 0.001)
        XCTAssertEqual(breakdown.fiberCalories ?? 0, 50, accuracy: 0.001)
    }

    func testLocalMealAnalysisReturnsCompleteNutritionForDescribedIngredients() async throws {
        let result = try await LocalMealNutritionAnalysisService().analyzeMeal(
            description: "chicken rice broccoli",
            photo: nil
        )

        XCTAssertEqual(result.detectedFoods.map(\.name), ["Chicken", "Rice", "Broccoli"])
        XCTAssertEqual(result.detectedFoods.reduce(0) { $0 + $1.nutrition.calories }, 595)
        XCTAssertEqual(result.detectedFoods.reduce(0) { $0 + $1.nutrition.proteinGrams }, 70, accuracy: 0.001)
        XCTAssertEqual(result.detectedFoods.reduce(0) { $0 + $1.nutrition.carbohydrateGrams }, 56, accuracy: 0.001)
        XCTAssertEqual(result.detectedFoods.reduce(0) { $0 + $1.nutrition.fatGrams }, 8, accuracy: 0.001)
        XCTAssertEqual(result.detectedFoods.reduce(0) { $0 + $1.nutrition.fiberGrams }, 6, accuracy: 0.001)
        XCTAssertTrue(result.notes?.contains("Local estimate") == true)
    }

    @MainActor
    func testMealAnalysisProvidesEditableFallbackEstimateAndRecalculatesCalories() async {
        let viewModel = MealLoggingViewModel()
        viewModel.updateFoodDescription("a homemade bowl")

        await viewModel.analyzeMeal()

        XCTAssertEqual(viewModel.analysisState, .ready)
        XCTAssertEqual(viewModel.detectedFoods.count, 1)
        guard let foodID = viewModel.detectedFoods.first?.id else {
            return XCTFail("Expected a fallback meal estimate")
        }

        viewModel.updateFoodMacros(id: foodID, protein: 30, carbohydrates: 40, fat: 10)

        XCTAssertEqual(viewModel.nutritionTotals.calories, 370)
        XCTAssertEqual(viewModel.nutritionTotals.proteinGrams, 30, accuracy: 0.001)
        XCTAssertEqual(viewModel.nutritionTotals.carbohydrateGrams, 40, accuracy: 0.001)
        XCTAssertEqual(viewModel.nutritionTotals.fatGrams, 10, accuracy: 0.001)
    }

    @MainActor
    func testProgressPhotoBodyFatEstimateAcceptsMeasuredRangeOnly() {
        let viewModel = ProgressPhotosViewModel()

        viewModel.bodyFatPercentageText = "22"
        XCTAssertEqual(viewModel.bodyFatPercentage, 22)
        XCTAssertTrue(viewModel.bodyFatEstimateText.contains("General range"))

        viewModel.bodyFatPercentageText = "85"
        XCTAssertNil(viewModel.bodyFatPercentage)
        XCTAssertEqual(viewModel.bodyFatEstimateText, "No body-fat estimate entered.")
    }

    private static func day(_ dayOffset: Double) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 + (86_400 * dayOffset))
    }
}
