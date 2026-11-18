import XCTest
import UIKit
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

    func testHabitAdherenceCountsWeeklyCheckInStreakAndCoverage() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let referenceDate = Self.day(0)
        let service = HabitAdherenceService(calendar: calendar)
        let snapshot = HabitAdherenceSnapshot(
            weightLogs: [
                WeightLog(recordedAt: referenceDate, weightKilograms: 80),
                WeightLog(recordedAt: Self.day(-7), weightKilograms: 81),
                WeightLog(recordedAt: Self.day(-14), weightKilograms: 82)
            ],
            referenceDate: referenceDate,
            checkInWindowDays: 28
        )

        let summary = service.buildSummary(from: snapshot)

        XCTAssertEqual(summary.checkInStreakWeeks, 3)
        XCTAssertEqual(summary.checkInWeeksLogged, 3)
        XCTAssertEqual(summary.checkInWeeksExpected, 4)
        XCTAssertEqual(summary.checkInCoveragePercent, 75)
    }

    func testHabitAdherenceKeepsYesterdayAndPreviousWeekStreaksAlive() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let referenceDate = Self.day(0)
        let service = HabitAdherenceService(calendar: calendar)
        let snapshot = HabitAdherenceSnapshot(
            mealEntries: [
                MealEntry(loggedAt: Self.day(-1), mealType: .lunch),
                MealEntry(loggedAt: Self.day(-2), mealType: .dinner)
            ],
            weightLogs: [
                WeightLog(recordedAt: Self.day(-7), weightKilograms: 81),
                WeightLog(recordedAt: Self.day(-14), weightKilograms: 82)
            ],
            referenceDate: referenceDate
        )

        let summary = service.buildSummary(from: snapshot)

        XCTAssertEqual(summary.mealLoggingStreakDays, 2)
        XCTAssertEqual(summary.checkInStreakWeeks, 2)
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
            "GoogleOAuthRedirectURI": "$(GOOGLE_OAUTH_REDIRECT_URI)",
            "GoogleOAuthScheme": "$(GOOGLE_OAUTH_SCHEME)"
        ])

        XCTAssertFalse(configuration.isConfigured)
    }

    func testOAuthConfigurationRequiresMatchingCallbackScheme() {
        let configuration = GoogleDriveConfiguration(info: [
            "GoogleOAuthClientID": "client.apps.googleusercontent.com",
            "GoogleOAuthRedirectURI": "com.example.dietum:/oauthredirect",
            "GoogleOAuthScheme": "com.example.other"
        ])

        XCTAssertFalse(configuration.isConfigured)
        XCTAssertTrue(configuration.missingConfigurationKeys.contains("GOOGLE_OAUTH_SCHEME (must match the redirect URI scheme)"))

        let validConfiguration = GoogleDriveConfiguration(info: [
            "GoogleOAuthClientID": "client.apps.googleusercontent.com",
            "GoogleOAuthRedirectURI": "com.example.dietum:/oauthredirect",
            "GoogleOAuthScheme": "com.example.dietum"
        ])

        XCTAssertTrue(validConfiguration.isConfigured)
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

    func testIngredientListParserAcceptsLinesSemicolonsAndDeduplicatesFoods() {
        let ingredients = MealIngredientListParser.parse("Chicken\n rice; broccoli and chicken • olive oil")

        XCTAssertEqual(ingredients, ["chicken", "rice", "broccoli", "olive oil"])
    }

    func testIngredientListParserExpandsIndianCompoundMealNames() {
        XCTAssertEqual(MealIngredientListParser.parse("daal chaval"), ["dal", "rice"])
        XCTAssertEqual(MealIngredientListParser.parse("dal chawal with yogurt"), ["dal", "rice", "yogurt"])
    }

    func testIndianRecipeCatalogProvidesNutritionWithoutUSDAKey() async throws {
        let recipe = IndianRecipeNutrition(
            id: "TEST-001",
            name: "Chicken Tikka",
            servingUnit: "bowl",
            per100Nutrition: NutritionAmounts(
                calories: 185,
                proteinGrams: 24,
                carbohydrateGrams: 5,
                fatGrams: 7,
                fiberGrams: 1,
                micronutrients: NutritionMicronutrients(sodiumMilligrams: 410, ironMilligrams: 1.2)
            )
        )
        let service = FoodDataCentralMealAnalysisService(
            configuration: FoodDataCentralConfiguration(info: ["USDAFoodDataCentralAPIKey": ""]),
            indianRecipeCatalog: BundledIndianRecipeCatalog(recipes: [recipe])
        )

        let result = try await service.analyzeMeal(description: "chicken tikka", photo: nil)

        XCTAssertEqual(result.detectedFoods.count, 1)
        XCTAssertEqual(result.detectedFoods.first?.name, "Chicken Tikka")
        XCTAssertEqual(result.detectedFoods.first?.nutrition.calories, 185)
        XCTAssertEqual(result.detectedFoods.first?.nutrition.micronutrients.sodiumMilligrams ?? 0, 410, accuracy: 0.001)
        XCTAssertTrue(result.notes?.contains("Indian Nutrient Databank") == true)
    }

    func testIndianCompoundMealResolvesDaalChavalIntoDalAndRice() async throws {
        let catalog = BundledIndianRecipeCatalog(recipes: [
            IndianRecipeNutrition(
                id: "TEST-005",
                name: "Mixed dal",
                servingUnit: "bowl",
                per100Nutrition: NutritionAmounts(calories: 115, proteinGrams: 7)
            ),
            IndianRecipeNutrition(
                id: "TEST-006",
                name: "Boiled rice (Uble chawal)",
                servingUnit: "cup",
                per100Nutrition: NutritionAmounts(calories: 130, carbohydrateGrams: 28)
            )
        ])
        let service = FoodDataCentralMealAnalysisService(
            configuration: FoodDataCentralConfiguration(info: ["USDAFoodDataCentralAPIKey": ""]),
            indianRecipeCatalog: catalog
        )

        let result = try await service.analyzeMeal(description: "daal chaval", photo: nil)

        XCTAssertEqual(result.detectedFoods.map(\.name), ["Mixed dal", "Boiled rice (Uble chawal)"])
    }

    func testIndianRecipeCatalogMatchesNormalizedMultiWordQueries() {
        let recipe = IndianRecipeNutrition(
            id: "TEST-002",
            name: "Palak Paneer (Spinach and Cottage Cheese)",
            servingUnit: "cup",
            per100Nutrition: NutritionAmounts(calories: 140)
        )
        let catalog = BundledIndianRecipeCatalog(recipes: [recipe])

        XCTAssertEqual(catalog.match(for: "PALAK PANEER")?.id, "TEST-002")
        XCTAssertNil(catalog.match(for: "sushi"))
    }

    func testIndianRecipeCatalogDoesNotMatchDalInsideDaliya() {
        let catalog = BundledIndianRecipeCatalog(recipes: [
            IndianRecipeNutrition(
                id: "TEST-003",
                name: "Cracked wheat porridge (Meetha daliya)",
                servingUnit: "bowl",
                per100Nutrition: NutritionAmounts(calories: 120)
            ),
            IndianRecipeNutrition(
                id: "TEST-004",
                name: "Mixed dal",
                servingUnit: "bowl",
                per100Nutrition: NutritionAmounts(calories: 110)
            )
        ])

        XCTAssertEqual(catalog.match(for: "dal")?.id, "TEST-004")
    }

    func testNutritionMicronutrientsScaleWithEditablePortion() {
        let per100Grams = NutritionAmounts(
            calories: 120,
            proteinGrams: 10,
            micronutrients: NutritionMicronutrients(
                sodiumMilligrams: 240,
                calciumMilligrams: 80,
                vitaminCMilligrams: 12
            )
        )

        let portion = per100Grams.scaled(toGrams: 250)

        XCTAssertEqual(portion.calories, 300)
        XCTAssertEqual(portion.micronutrients.sodiumMilligrams, 600, accuracy: 0.001)
        XCTAssertEqual(portion.micronutrients.calciumMilligrams, 200, accuracy: 0.001)
        XCTAssertEqual(portion.micronutrients.vitaminCMilligrams, 30, accuracy: 0.001)
    }

    func testNutritionAmountsDecodesLegacyMealDataWithoutMicronutrients() throws {
        let legacyData = Data("{\"calories\":100,\"proteinGrams\":5,\"carbohydrateGrams\":10,\"fatGrams\":2,\"fiberGrams\":1}".utf8)
        let nutrition = try JSONDecoder().decode(NutritionAmounts.self, from: legacyData)

        XCTAssertEqual(nutrition.calories, 100)
        XCTAssertEqual(nutrition.proteinGrams, 5, accuracy: 0.001)
        XCTAssertEqual(nutrition.micronutrients.sodiumMilligrams, 0, accuracy: 0.001)
    }

    func testFoodDataCentralAnalysisRequiresConfiguredAPIKey() async {
        let service = FoodDataCentralMealAnalysisService(
            configuration: FoodDataCentralConfiguration(info: ["USDAFoodDataCentralAPIKey": ""])
        )

        do {
            _ = try await service.analyzeMeal(description: "chicken rice broccoli", photo: nil)
            XCTFail("Expected the production analyzer to reject an unconfigured USDA key")
        } catch let error as FoodDataCentralMealAnalysisError {
            XCTAssertEqual(error, .missingAPIKey)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDetectedFoodCalculatesEditableNutritionFromPer100Grams() async throws {
        let food = DetectedMealFood(
            name: "Chicken",
            confidence: 0.9,
            estimatedWeightGrams: 150,
            nutritionPer100Grams: NutritionAmounts(calories: 165, proteinGrams: 31, fatGrams: 3.6)
        )

        XCTAssertEqual(food.nutrition.calories, 248)
        XCTAssertEqual(food.nutrition.proteinGrams, 46.5, accuracy: 0.001)
        XCTAssertEqual(food.nutrition.fatGrams, 5.4, accuracy: 0.001)
    }

    @MainActor
    func testMealAnalysisProvidesEditableFallbackEstimateAndRecalculatesCalories() async {
        let service = TestMealFoodDetectionService(
            result: MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(
                        name: "General meal estimate",
                        confidence: 0.35,
                        estimatedWeightGrams: 350,
                        nutritionPer100Grams: NutritionAmounts(
                            calories: 143,
                            proteinGrams: 7.1,
                            carbohydrateGrams: 15.7,
                            fatGrams: 5.1,
                            fiberGrams: 1.7
                        )
                    )
                ],
                notes: "Test estimate"
            )
        )
        let viewModel = MealLoggingViewModel(detectionService: service)
        viewModel.updateFoodDescription("a homemade bowl")

        await viewModel.analyzeMeal()

        XCTAssertEqual(viewModel.analysisState, .ready)
        XCTAssertEqual(viewModel.detectedFoods.count, 1)
        guard let foodID = viewModel.detectedFoods.first?.id else {
            return XCTFail("Expected a fallback meal estimate")
        }

        viewModel.updateFoodWeight(id: foodID, grams: 200)
        XCTAssertEqual(viewModel.nutritionTotals.calories, 286)

        viewModel.updateFoodMacros(id: foodID, protein: 30, carbohydrates: 40, fat: 10)

        XCTAssertEqual(viewModel.nutritionTotals.calories, 370)
        XCTAssertEqual(viewModel.nutritionTotals.proteinGrams, 30, accuracy: 0.001)
        XCTAssertEqual(viewModel.nutritionTotals.carbohydrateGrams, 40, accuracy: 0.001)
        XCTAssertEqual(viewModel.nutritionTotals.fatGrams, 10, accuracy: 0.001)
    }

    @MainActor
    func testNutritionLabelServingCountRecalculatesEditableTotals() async {
        let service = TestMealFoodDetectionService(
            result: MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(
                        name: "Packaged cereal",
                        confidence: 0.98,
                        estimatedWeightGrams: 30,
                        servingSizeGrams: 30,
                        servings: 1,
                        nutritionPer100Grams: NutritionAmounts(
                            calories: 400,
                            proteinGrams: 10,
                            carbohydrateGrams: 80,
                            fatGrams: 5
                        )
                    )
                ],
                notes: "Nutrition label read"
            )
        )
        let viewModel = MealLoggingViewModel(detectionService: service)
        viewModel.setSelectedPhoto(UIImage())
        await viewModel.analyzeMeal()

        guard let foodID = viewModel.detectedFoods.first?.id else {
            return XCTFail("Expected a nutrition-label food")
        }

        viewModel.updateFoodServings(id: foodID, servings: 2.5)

        XCTAssertEqual(viewModel.detectedFoods.first?.estimatedWeightGrams ?? 0, 75, accuracy: 0.001)
        XCTAssertEqual(viewModel.nutritionTotals.calories, 300)
        XCTAssertEqual(viewModel.nutritionTotals.carbohydrateGrams, 60, accuracy: 0.001)
    }

    @MainActor
    func testMealSavePersistsSelectedPhotoWithoutManualReviewToggle() async throws {
        let container = try DietumPersistenceStack.makeContainer(inMemory: true)
        let repository = SwiftDataMealEntryRepository(modelContext: container.mainContext)
        let service = TestMealFoodDetectionService(
            result: MealFoodDetectionResult(
                detectedFoods: [
                    DetectedMealFood(
                        name: "Chicken and rice",
                        confidence: 0.8,
                        estimatedWeightGrams: 300,
                        nutritionPer100Grams: NutritionAmounts(
                            calories: 160,
                            proteinGrams: 12,
                            carbohydrateGrams: 20,
                            fatGrams: 4,
                            fiberGrams: 1,
                            micronutrients: NutritionMicronutrients(sodiumMilligrams: 180, vitaminCMilligrams: 9)
                        )
                    )
                ],
                notes: "Test estimate"
            )
        )
        let viewModel = MealLoggingViewModel(
            draft: MealLoggingDraft(foodDescription: "chicken rice"),
            detectionService: service,
            mealEntryRepository: repository
        )
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { context in
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }

        viewModel.setSelectedPhoto(image)
        await viewModel.analyzeMeal()

        XCTAssertTrue(viewModel.canSave)
        XCTAssertTrue(viewModel.reviewedItemIDs.isEmpty)

        await viewModel.saveDraft()

        let entries = try await repository.fetchMealEntries(
            in: DateInterval(start: Calendar.current.startOfDay(for: .now), end: .distantFuture)
        )
        XCTAssertEqual(viewModel.analysisState, .saved)
        XCTAssertEqual(entries.count, 1)
        XCTAssertNotNil(entries.first?.photoMetadata?.imageData)
        XCTAssertEqual(entries.first?.nutrition.micronutrients.sodiumMilligrams ?? 0, 540, accuracy: 0.001)
        XCTAssertEqual(entries.first?.nutrition.micronutrients.vitaminCMilligrams ?? 0, 27, accuracy: 0.001)
        XCTAssertEqual(viewModel.todaySavedMeals.count, 1)
    }

    @MainActor
    func testMealHistoryDeletesOnlyPhotoEntriesForSelectedDay() async throws {
        let container = try DietumPersistenceStack.makeContainer(inMemory: true)
        let repository = SwiftDataMealEntryRepository(modelContext: container.mainContext)
        let selectedDay = Self.day(0)
        let otherDay = Self.day(-1)

        try await repository.saveMealEntry(
            MealEntry(
                loggedAt: selectedDay,
                mealType: .lunch,
                photoMetadata: PhotoMetadata(storageIdentifier: "meal-selected", capturedAt: selectedDay),
                nutrition: NutritionAmounts(calories: 600, proteinGrams: 30, carbohydrateGrams: 70, fatGrams: 20)
            )
        )
        try await repository.saveMealEntry(
            MealEntry(
                loggedAt: selectedDay,
                mealType: .dinner,
                nutrition: NutritionAmounts(calories: 500)
            )
        )
        try await repository.saveMealEntry(
            MealEntry(
                loggedAt: otherDay,
                mealType: .breakfast,
                photoMetadata: PhotoMetadata(storageIdentifier: "meal-other", capturedAt: otherDay),
                nutrition: NutritionAmounts(calories: 400)
            )
        )

        let viewModel = MealHistoryViewModel(mealEntryRepository: repository)
        await viewModel.loadHistory()
        await viewModel.deleteMealPhotoDay(selectedDay)

        let remaining = try await repository.fetchMealEntries(
            in: DateInterval(start: Self.day(-2), end: Self.day(1))
        )
        XCTAssertEqual(remaining.count, 2)
        XCTAssertTrue(remaining.contains { $0.loggedAt == selectedDay && $0.photoMetadata == nil })
        XCTAssertTrue(remaining.contains { $0.loggedAt == otherDay && $0.photoMetadata != nil })
        XCTAssertTrue(viewModel.dayGroups.allSatisfy {
            !Calendar.current.isDate($0.day, inSameDayAs: selectedDay)
        })
    }

    @MainActor
    func testProgressPhotoBodyFatEstimateAcceptsMeasuredRangeOnly() {
        let viewModel = ProgressPhotosViewModel()

        viewModel.bodyFatPercentageText = "22"
        XCTAssertEqual(viewModel.bodyFatPercentage, 22)
        XCTAssertTrue(viewModel.bodyFatEstimateText.contains("General range"))

        viewModel.bodyFatPercentageText = "85"
        XCTAssertNil(viewModel.bodyFatPercentage)
        XCTAssertEqual(viewModel.bodyFatEstimateText, "Upload a photo set to choose a visual body-fat range.")

        viewModel.selectBodyFatReference(BodyFatReferenceBand.guide[1])
        XCTAssertEqual(viewModel.bodyFatEstimateText, "Visual estimate: Active range (10-20%).")
    }

    @MainActor
    func testProgressPhotoComparisonReportsOverallAndRegionalChanges() {
        let viewModel = ProgressPhotosViewModel()
        let earlier = Self.day(0)
        let later = Self.day(14)
        viewModel.recentPhotos = [
            ProgressPhotoMetadata(
                capturedAt: earlier,
                angle: .front,
                photo: PhotoMetadata(storageIdentifier: "comparison-earlier"),
                bodyFatPercentage: 24,
                bodyFatBreakdown: BodyFatEstimateBreakdown(
                    chestPercentage: 24,
                    armsPercentage: 23,
                    legsPercentage: 26,
                    backPercentage: 25,
                    visceralPercentage: 21.6
                )
            ),
            ProgressPhotoMetadata(
                capturedAt: later,
                angle: .front,
                photo: PhotoMetadata(storageIdentifier: "comparison-later"),
                bodyFatPercentage: 22,
                bodyFatBreakdown: BodyFatEstimateBreakdown(
                    chestPercentage: 22,
                    armsPercentage: 22,
                    legsPercentage: 25,
                    backPercentage: 23,
                    visceralPercentage: 19.8
                )
            )
        ]

        viewModel.setComparisonAngle(.front)

        XCTAssertEqual(viewModel.comparisonChanges.first?.title, "Overall")
        XCTAssertEqual(viewModel.comparisonChanges.first?.detail, "Down by 2.0 percentage points: 24.0% to 22.0%")
        XCTAssertTrue(viewModel.comparisonChanges.contains { $0.title == "Chest" && $0.detail.contains("Down by 2.0") })
        XCTAssertTrue(viewModel.comparisonChanges.contains { $0.title == "Arms" && $0.detail.contains("Down by 1.0") })
        XCTAssertEqual(viewModel.comparisonCompositionSignals.map(\.title), ["Fat change", "Muscle composition", "Shape change"])
        XCTAssertTrue(viewModel.comparisonCompositionSignals[1].detail.contains("not measurable"))
        XCTAssertTrue(viewModel.comparisonCompositionSignals[2].detail.contains("waist"))
        XCTAssertFalse(viewModel.comparisonDetail.localizedCaseInsensitiveContains("lighting"))
        XCTAssertTrue(viewModel.comparisonDetail.localizedCaseInsensitiveContains("composition"))
    }

    @MainActor
    func testProgressPhotoStagesAndAnalyzesBeforeSave() async {
        let viewModel = ProgressPhotosViewModel()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }

        await viewModel.stagePhotoAndAnalyze(for: .left, image: image)

        XCTAssertNotNil(viewModel.stagedPhoto(for: .left))
        XCTAssertFalse(viewModel.chestBodyFatText.isEmpty)
        XCTAssertFalse(viewModel.legsBodyFatText.isEmpty)
        XCTAssertTrue(viewModel.bodyAnalysisText.contains("loaded") || viewModel.bodyAnalysisText.contains("Body detected"))
    }

    @MainActor
    func testProgressPhotoRepositoryRoundTripsImageData() async throws {
        let container = try DietumPersistenceStack.makeContainer(inMemory: true)
        let repository = SwiftDataProgressPhotoRepository(modelContext: container.mainContext)
        let capturedAt = Self.day(0)
        let imageData = Data([0, 1, 2, 3])
        let photo = ProgressPhotoMetadata(
            capturedAt: capturedAt,
            angle: .front,
            photo: PhotoMetadata(
                storageIdentifier: "progress-photo-front-01",
                capturedAt: capturedAt,
                imageData: imageData
            ),
            bodyFatBreakdown: BodyFatEstimateBreakdown(
                chestPercentage: 22.0,
                armsPercentage: 21.0,
                legsPercentage: 24.0,
                backPercentage: 23.0,
                visceralPercentage: 19.8
            )
        )

        try await repository.saveProgressPhoto(photo)
        let results = try await repository.fetchProgressPhotos(in: DateInterval(start: Self.day(-1), end: Self.day(1)))

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.photo.imageData, imageData)
        XCTAssertEqual(results.first?.bodyFatBreakdown?.legsPercentage, 24.0)
        XCTAssertEqual(results.first?.bodyFatBreakdown?.visceralPercentage, 19.8)
    }

    @MainActor
    func testProgressPhotoDayDeletionRemovesOnlyTheSelectedDate() async throws {
        let container = try DietumPersistenceStack.makeContainer(inMemory: true)
        let repository = SwiftDataProgressPhotoRepository(modelContext: container.mainContext)
        let firstDay = Self.day(0)
        let secondDay = Self.day(1)

        for (index, angle) in [ProgressPhotoAngle.front, .back].enumerated() {
            try await repository.saveProgressPhoto(
                ProgressPhotoMetadata(
                    capturedAt: firstDay,
                    angle: angle,
                    photo: PhotoMetadata(
                        storageIdentifier: "progress-photo-first-\(index)",
                        capturedAt: firstDay,
                        imageData: Data([UInt8(index)])
                    )
                )
            )
        }

        try await repository.saveProgressPhoto(
            ProgressPhotoMetadata(
                capturedAt: secondDay,
                angle: .front,
                photo: PhotoMetadata(
                    storageIdentifier: "progress-photo-second",
                    capturedAt: secondDay,
                    imageData: Data([3])
                )
            )
        )

        let viewModel = ProgressPhotosViewModel(progressPhotoRepository: repository)
        await viewModel.loadRecentPhotos()
        XCTAssertEqual(viewModel.recentPhotoGroups.count, 2)

        await viewModel.deletePhotoDay(firstDay)

        XCTAssertEqual(viewModel.recentPhotos.count, 1)
        XCTAssertEqual(viewModel.recentPhotoGroups.count, 1)
        XCTAssertTrue(Calendar.current.isDate(viewModel.recentPhotos[0].capturedAt, inSameDayAs: secondDay))
    }

    @MainActor
    func testSleepSetupImportsHealthDataIntoEditableFields() async {
        let bedtime = Self.day(-0.25)
        let wakeTime = Self.day(0)
        let importer = StubSleepHealthImporter(
            result: ImportedSleepWindow(bedtime: bedtime, wakeTime: wakeTime)
        )
        let viewModel = SleepSetupViewModel(sleepHealthImporter: importer)

        await viewModel.importSleepFromHealthKit()

        XCTAssertEqual(viewModel.healthImportState, .imported)
        XCTAssertEqual(viewModel.importedSleep?.bedtime, bedtime)
        XCTAssertEqual(viewModel.averageSleepHours, "6.0")
        XCTAssertTrue(viewModel.sleepSchedule.contains("Bedtime"))
    }

    @MainActor
    func testDashboardSleepInsightsAveragesInferredDoomScrollWindows() async {
        let firstNight = ImportedSleepWindow(
            bedtime: Self.day(-2),
            sleepStart: Self.day(-2 + 0.25),
            wakeTime: Self.day(-1),
            outOfBedTime: Self.day(-1 + 0.125)
        )
        let secondNight = ImportedSleepWindow(
            bedtime: Self.day(-1),
            sleepStart: Self.day(-1 + 0.125),
            wakeTime: Self.day(0),
            outOfBedTime: Self.day(0 + 0.25)
        )
        let importer = StubSleepHealthImporter(
            result: secondNight,
            recentResults: [firstNight, secondNight]
        )
        let viewModel = DashboardViewModel(sleepHealthImporter: importer)

        await viewModel.loadSleepInsights()

        XCTAssertEqual(viewModel.sleepSummary.nightCount, 2)
        XCTAssertEqual(viewModel.sleepSummary.averagePreSleepDoomScrollDuration ?? -1, 16_200, accuracy: 0.001)
        XCTAssertEqual(viewModel.sleepSummary.averagePostWakeDoomScrollDuration ?? -1, 16_200, accuracy: 0.001)
        XCTAssertEqual(viewModel.sleepInsightCards[2].value, "4h 30m")
        XCTAssertEqual(viewModel.sleepInsightCards[3].value, "4h 30m")
    }

    private static func day(_ dayOffset: Double) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 + (86_400 * dayOffset))
    }
}

private struct TestMealFoodDetectionService: MealFoodDetectionService {
    let result: MealFoodDetectionResult

    func analyzeMeal(description: String, photo: PhotoMetadata?) async throws -> MealFoodDetectionResult {
        result
    }
}

private struct StubSleepHealthImporter: SleepHealthImporting {
    let result: ImportedSleepWindow
    var recentResults: [ImportedSleepWindow]?

    init(result: ImportedSleepWindow, recentResults: [ImportedSleepWindow]? = nil) {
        self.result = result
        self.recentResults = recentResults
    }

    func importLatestSleepWindow() async throws -> ImportedSleepWindow {
        result
    }

    func importRecentSleepWindows(days: Int) async throws -> [ImportedSleepWindow] {
        recentResults ?? [result]
    }
}
