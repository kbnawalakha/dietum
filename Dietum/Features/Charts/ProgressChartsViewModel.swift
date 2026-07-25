import Foundation
import SwiftUI

@MainActor
final class ProgressChartsViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    struct WeightChartPoint: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    struct NutritionChartPoint: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var weightPoints: [WeightChartPoint] = []
    @Published private(set) var nutritionPoints: [NutritionChartPoint] = []

    private let weightLogRepository: any WeightLogRepository
    private let recommendationService: any NutritionAdjustmentRecommendationService
    private let goalWeightKilograms: Double
    private let baseNutritionTarget: NutritionTarget

    init(
        weightLogRepository: any WeightLogRepository,
        recommendationService: any NutritionAdjustmentRecommendationService,
        goalWeightKilograms: Double = 79.5,
        baseNutritionTarget: NutritionTarget = NutritionTarget(
            dailyGoal: NutritionAmounts(
                calories: 2_400,
                proteinGrams: 180,
                carbohydrateGrams: 240,
                fatGrams: 70,
                fiberGrams: 30
            ),
            updatedAt: .now,
            isActive: true
        )
    ) {
        self.weightLogRepository = weightLogRepository
        self.recommendationService = recommendationService
        self.goalWeightKilograms = goalWeightKilograms
        self.baseNutritionTarget = baseNutritionTarget
    }

    func loadCharts() async {
        guard loadState != .loading else {
            return
        }

        loadState = .loading

        do {
            let start = Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now
            let window = DateInterval(start: start, end: .now)
            let logs = try await weightLogRepository.fetchWeightLogs(in: window)
            let sortedLogs = logs.sorted { $0.recordedAt < $1.recordedAt }

            if sortedLogs.isEmpty {
                applySampleData()
                loadState = .loaded
                return
            }

            weightPoints = sortedLogs.map { WeightChartPoint(date: $0.recordedAt, value: $0.weightKilograms) }
            nutritionPoints = try await buildNutritionSeries(from: sortedLogs)
            loadState = .loaded
        } catch {
            applySampleData()
            loadState = .failed("Unable to load progress charts right now.")
        }
    }

    var heroHeadline: String {
        switch loadState {
        case .loading:
            return "Building your trend lines from local history."
        case .failed(let message):
            return message
        case .idle, .loaded:
            return "See how weight and nutrition are moving together over time."
        }
    }

    var weightSummaryText: String {
        guard let first = weightPoints.first, let last = weightPoints.last else {
            return "No weight history yet."
        }

        let delta = last.value - first.value
        let formatted = String(format: "%.1f", abs(delta))
        if abs(delta) < 0.1 {
            return "Weight is essentially flat across the current window."
        }

        return delta > 0 ? "Weight is up \(formatted) kg across the current window." : "Weight is down \(formatted) kg across the current window."
    }

    var nutritionSummaryText: String {
        guard let first = nutritionPoints.first, let last = nutritionPoints.last else {
            return "No calorie trend available yet."
        }

        let delta = last.value - first.value
        let formatted = String(format: "%.0f", abs(delta))
        if abs(delta) < 1 {
            return "Suggested calories are holding steady across the current window."
        }

        return delta > 0 ? "Suggested calories are up by \(formatted) kcal." : "Suggested calories are down by \(formatted) kcal."
    }

    var currentWeightText: String {
        guard let latest = weightPoints.last else { return "—" }
        return String(format: "%.1f kg", latest.value)
    }

    var weightChangeText: String {
        guard let first = weightPoints.first, let last = weightPoints.last else { return "—" }
        let delta = last.value - first.value
        let formatted = String(format: "%.1f kg", abs(delta))
        if abs(delta) < 0.1 {
            return "Flat"
        }

        return delta > 0 ? "+\(formatted)" : "-\(formatted)"
    }

    var currentCaloriesText: String {
        guard let latest = nutritionPoints.last else { return "—" }
        return "\(Int(latest.value)) kcal"
    }

    var caloriesDeltaText: String {
        guard let first = nutritionPoints.first, let last = nutritionPoints.last else { return "—" }
        let delta = Int(last.value.rounded()) - Int(first.value.rounded())
        if delta == 0 {
            return "No change"
        }

        let formatted = abs(delta)
        return delta > 0 ? "+\(formatted) kcal" : "-\(formatted) kcal"
    }

    var goalWeightText: String {
        String(format: "%.1f kg", goalWeightKilograms)
    }

    var goalWeightValue: Double {
        goalWeightKilograms
    }

    var currentTargetText: String {
        "\(baseNutritionTarget.dailyGoal.calories) kcal"
    }

    var supportingSignals: [String] {
        [
            "Weight history is based on the latest local check-ins.",
            "Nutrition points mirror the recommendation service over the same window.",
            "The goal line is fixed at \(goalWeightText) for this view."
        ]
    }

    var chartNotes: String {
        switch loadState {
        case .loading:
            return "Refreshing the charts..."
        case .failed:
            return "Fallback sample data is being shown."
        case .idle, .loaded:
            return "Charts update from local data only."
        }
    }

    private func buildNutritionSeries(from logs: [WeightLog]) async throws -> [NutritionChartPoint] {
        guard logs.count > 1 else {
            return [NutritionChartPoint(date: logs.last?.recordedAt ?? .now, value: Double(baseNutritionTarget.dailyGoal.calories))]
        }

        var points: [NutritionChartPoint] = []

        for endIndex in 1..<logs.count {
            let prefix = Array(logs.prefix(endIndex + 1))
            let input = NutritionTrendAnalysisInput(
                currentNutritionTarget: baseNutritionTarget,
                recentWeightLogs: prefix,
                goalWeightKilograms: goalWeightKilograms,
                recentAverageCalories: baseNutritionTarget.dailyGoal.calories
            )

            if let recommendation = try await recommendationService.recommendAdjustment(from: input) {
                let date = prefix.last?.recordedAt ?? .now
                points.append(NutritionChartPoint(date: date, value: Double(recommendation.suggestedDailyCalories)))
            }
        }

        if let latest = logs.last, points.isEmpty {
            points.append(NutritionChartPoint(date: latest.recordedAt, value: Double(baseNutritionTarget.dailyGoal.calories)))
        }

        return points
    }

    private func applySampleData() {
        let calendar = Calendar.current
        let sampleWeights: [Double] = [81.9, 81.7, 81.8, 81.6]
        let sampleCalories: [Double] = [2_400, 2_300, 2_300, 2_250]

        weightPoints = sampleWeights.enumerated().compactMap { offset, value in
            guard let date = calendar.date(byAdding: .day, value: -21 + (offset * 7), to: .now) else {
                return nil
            }
            return WeightChartPoint(date: date, value: value)
        }

        nutritionPoints = sampleCalories.enumerated().compactMap { offset, value in
            guard let date = calendar.date(byAdding: .day, value: -21 + (offset * 7), to: .now) else {
                return nil
            }
            return NutritionChartPoint(date: date, value: value)
        }
    }
}
