import Foundation
import SwiftUI

@MainActor
final class NutritionAdjustmentViewModel: ObservableObject {
    enum ReviewState: Equatable {
        case idle
        case loading
        case ready
        case approved(Date)
        case declined
        case failed(String)
    }

    @Published var recommendation: CalorieAdjustmentRecommendation?
    @Published var reviewState: ReviewState = .idle
    @Published var approvalNotes: String = ""
    @Published var appliedCalories: Int?

    private let recommendationService: any NutritionAdjustmentRecommendationService
    private let input: NutritionTrendAnalysisInput

    init(
        recommendationService: any NutritionAdjustmentRecommendationService = DeterministicNutritionAdjustmentRecommendationService(),
        input: NutritionTrendAnalysisInput = NutritionTrendAnalysisInput(
            currentNutritionTarget: NutritionTarget(
                dailyGoal: NutritionAmounts(
                    calories: 2_400,
                    proteinGrams: 180,
                    carbohydrateGrams: 240,
                    fatGrams: 70,
                    fiberGrams: 30
                ),
                updatedAt: .now,
                isActive: true
            ),
            recentWeightLogs: [
                WeightLog(recordedAt: Calendar.current.date(byAdding: .day, value: -21, to: .now) ?? .now, weightKilograms: 81.9, notes: "Weekly check-in"),
                WeightLog(recordedAt: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now, weightKilograms: 81.7, notes: "Weekly check-in"),
                WeightLog(recordedAt: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now, weightKilograms: 81.8, notes: "Weekly check-in"),
                WeightLog(recordedAt: .now, weightKilograms: 81.8, notes: "Weekly check-in")
            ],
            goalWeightKilograms: 79.5,
            goalDate: Calendar.current.date(byAdding: .month, value: 2, to: .now),
            recentAverageCalories: 2_350
        )
    ) {
        self.recommendationService = recommendationService
        self.input = input
    }

    func loadRecommendation() async {
        guard reviewState != .loading else {
            return
        }

        reviewState = .loading
        approvalNotes = ""

        do {
            recommendation = try await recommendationService.recommendAdjustment(from: input)
            reviewState = .ready
        } catch {
            recommendation = nil
            reviewState = .failed("Unable to build a nutrition adjustment right now.")
        }
    }

    func approveRecommendation() {
        guard let recommendation, reviewState == .ready else {
            return
        }

        appliedCalories = recommendation.suggestedDailyCalories
        approvalNotes = "Approved \(recommendation.calorieDelta > 0 ? "increase" : recommendation.calorieDelta < 0 ? "decrease" : "hold") to \(recommendation.suggestedDailyCalories) calories."
        reviewState = .approved(.now)
    }

    func declineRecommendation() {
        approvalNotes = "Kept the current target unchanged."
        reviewState = .declined
    }

    var headline: String {
        switch reviewState {
        case .idle:
            return "Review a local calorie adjustment recommendation before it is applied."
        case .loading:
            return "Analyzing recent weight trends locally."
        case .ready:
            return "A calorie adjustment is ready for your approval."
        case .approved:
            return "The approved change is recorded locally."
        case .declined:
            return "The current target stays active for now."
        case .failed(let message):
            return message
        }
    }

    var currentCaloriesText: String {
        guard let recommendation else { return "—" }
        return "\(recommendation.currentDailyCalories) kcal"
    }

    var suggestedCaloriesText: String {
        guard let recommendation else { return "—" }
        return "\(recommendation.suggestedDailyCalories) kcal"
    }

    var deltaText: String {
        guard let recommendation else { return "—" }
        let formatted = abs(recommendation.calorieDelta)
        if recommendation.calorieDelta == 0 {
            return "No change"
        }
        return recommendation.calorieDelta > 0 ? "+\(formatted) kcal" : "-\(formatted) kcal"
    }

    var canApprove: Bool {
        recommendation != nil && reviewState == .ready
    }

    var approvalButtonTitle: String {
        switch reviewState {
        case .approved:
            return "Approved"
        case .ready:
            return "Approve adjustment"
        case .loading:
            return "Analyzing..."
        case .declined:
            return "Keep current target"
        case .idle, .failed:
            return "Approve adjustment"
        }
    }

    var approvalBadgeText: String {
        switch reviewState {
        case .approved:
            return "Applied locally"
        case .declined:
            return "Not applied"
        case .ready:
            return "Awaiting approval"
        case .loading:
            return "Loading"
        case .idle:
            return "Preview only"
        case .failed:
            return "Needs attention"
        }
    }
}

