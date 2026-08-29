import Foundation
import SwiftUI

@MainActor
final class NutritionTrendInsightsViewModel: ObservableObject {
    @Published private(set) var state: NutritionTrendInsightsState = .idle

    private let mealEntryRepository: any MealEntryRepository
    private let nutritionTargetRepository: (any NutritionTargetRepository)?
    private let service: any NutritionTrendInsightsServicing
    private let calendar: Calendar

    init(
        mealEntryRepository: any MealEntryRepository,
        nutritionTargetRepository: (any NutritionTargetRepository)? = nil,
        service: any NutritionTrendInsightsServicing = NutritionTrendInsightsService(),
        calendar: Calendar = .current
    ) {
        self.mealEntryRepository = mealEntryRepository
        self.nutritionTargetRepository = nutritionTargetRepository
        self.service = service
        self.calendar = calendar
    }

    func load(referenceDate: Date = .now) async {
        guard state != .loading else { return }
        state = .loading

        do {
            let end = calendar.startOfDay(for: referenceDate)
            let start = calendar.date(byAdding: .day, value: -13, to: end) ?? end
            let entries = try await mealEntryRepository.fetchMealEntries(in: DateInterval(start: start, end: referenceDate))
            let target = try await nutritionTargetRepository?.fetchActiveNutritionTarget()?.dailyGoal
            let insights = service.makeInsights(
                from: NutritionTrendInsightsInput(
                    mealEntries: entries,
                    referenceDate: referenceDate,
                    target: target
                )
            )
            state = insights.map(NutritionTrendInsightsState.loaded) ?? .empty
        } catch {
            state = .failed(message: "Unable to load nutrition trends right now. Try again to refresh local history.")
        }
    }

    func retry() async {
        await load()
    }

    var headline: String {
        switch state {
        case .idle, .loaded:
            return "A plain-language view of what your recent meal logs show."
        case .loading:
            return "Reviewing your recent local meal history."
        case .empty:
            return "Log a few meals to reveal a useful pattern."
        case .failed(let message):
            return message
        }
    }

    var estimateNote: String {
        guard case .loaded(let insights) = state else { return "" }
        return insights.isEstimate
            ? "Estimate only: this uses \(insights.sampleDescription.lowercased()). Missing days can change the pattern."
            : "Estimate from logged meals only. This describes a pattern; it is not medical advice or a nutrition prescription."
    }
}
