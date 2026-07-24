import Foundation

protocol NutritionAdjustmentRecommendationService: Sendable {
    func analyzeTrend(from input: NutritionTrendAnalysisInput) async throws -> NutritionTrendAnalysisOutput
    func recommendAdjustment(from input: NutritionTrendAnalysisInput) async throws -> CalorieAdjustmentRecommendation?
}

struct DeterministicNutritionAdjustmentRecommendationService: NutritionAdjustmentRecommendationService {
    func analyzeTrend(from input: NutritionTrendAnalysisInput) async throws -> NutritionTrendAnalysisOutput {
        let sortedLogs = input.recentWeightLogs.sorted { $0.recordedAt < $1.recordedAt }

        guard let first = sortedLogs.first, let last = sortedLogs.last, sortedLogs.count > 1 else {
            return NutritionTrendAnalysisOutput(
                averageWeeklyWeightChangeKilograms: 0,
                totalWeightChangeKilograms: 0,
                trendDirection: .maintain,
                summary: "Not enough weight data yet to estimate a trend.",
                supportingSignals: ["Add another weekly check-in to make the trend more reliable."]
            )
        }

        let totalWeightChange = last.weightKilograms - first.weightKilograms
        let spanDays = max(last.recordedAt.timeIntervalSince(first.recordedAt) / 86_400, 1)
        let weeks = max(spanDays / 7, 1)
        let weeklyChange = totalWeightChange / weeks

        let trendDirection: NutritionTrendDirection
        let summary: String

        if weeklyChange <= -0.2 {
            trendDirection = .cut
            summary = "Weight is trending down at a steady pace."
        } else if weeklyChange >= 0.2 {
            trendDirection = .increase
            summary = "Weight is trending up over the recent window."
        } else {
            trendDirection = .maintain
            summary = "Weight is mostly flat across the recent window."
        }

        var signals = [
            "Tracked \(sortedLogs.count) weight entries across about \(String(format: "%.1f", weeks)) week(s).",
            "Latest weight is \(String(format: "%.1f", last.weightKilograms)) kg."
        ]

        if let goal = input.goalWeightKilograms {
            let gap = last.weightKilograms - goal
            signals.append("Current weight is \(String(format: "%.1f", abs(gap))) kg \(gap > 0 ? "above" : "below") the goal.")
        }

        return NutritionTrendAnalysisOutput(
            averageWeeklyWeightChangeKilograms: weeklyChange,
            totalWeightChangeKilograms: totalWeightChange,
            trendDirection: trendDirection,
            summary: summary,
            supportingSignals: signals
        )
    }

    func recommendAdjustment(from input: NutritionTrendAnalysisInput) async throws -> CalorieAdjustmentRecommendation? {
        let analysis = try await analyzeTrend(from: input)
        let currentCalories = input.currentNutritionTarget.dailyGoal.calories
        let latestWeight = input.recentWeightLogs.sorted { $0.recordedAt < $1.recordedAt }.last?.weightKilograms
        let goalWeight = input.goalWeightKilograms

        guard let latestWeight, let goalWeight else {
            return CalorieAdjustmentRecommendation(
                currentDailyCalories: currentCalories,
                suggestedDailyCalories: currentCalories,
                calorieDelta: 0,
                reasonSummary: "Keep the current target until the goal context is filled in.",
                expectedEffect: "No change to the calorie target yet.",
                supportingReasons: analysis.supportingSignals,
                trendAnalysis: analysis
            )
        }

        let goalGap = latestWeight - goalWeight
        let weeklyChange = analysis.averageWeeklyWeightChangeKilograms
        let adjustment: Int
        let reason: String
        let expectedEffect: String

        if goalGap > 0.5 {
            if weeklyChange <= -0.2 {
                adjustment = -100
                reason = "Weight is moving down, but the pace is measured enough to keep a small deficit."
                expectedEffect = "A slightly lower target should keep the trend moving without feeling aggressive."
            } else if weeklyChange >= 0.2 {
                adjustment = -200
                reason = "Weight has been flat or rising while the goal is still below the current weight."
                expectedEffect = "A larger reduction should restart progress toward the goal."
            } else {
                adjustment = -150
                reason = "Weight is flat while the goal is still below the current weight."
                expectedEffect = "A modest reduction should nudge the trend down."
            }
        } else if goalGap < -0.5 {
            if weeklyChange >= 0.2 {
                adjustment = 150
                reason = "Weight is already trending up while the goal sits below the current weight."
                expectedEffect = "A small increase should slow the upward drift."
            } else {
                adjustment = 100
                reason = "You are already below the goal and the current pace looks a little fast."
                expectedEffect = "A small increase should support steadier maintenance."
            }
        } else {
            adjustment = 0
            reason = "Current weight is close to the goal, so keeping the target steady is the safest choice."
            expectedEffect = "Maintain the current target and revisit after more check-ins."
        }

        let suggestedCalories = max(1, currentCalories + adjustment)

        return CalorieAdjustmentRecommendation(
            currentDailyCalories: currentCalories,
            suggestedDailyCalories: suggestedCalories,
            calorieDelta: adjustment,
            reasonSummary: reason,
            expectedEffect: expectedEffect,
            supportingReasons: analysis.supportingSignals,
            trendAnalysis: analysis
        )
    }
}

