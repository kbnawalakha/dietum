import Foundation

protocol NutritionTrendInsightsServicing: Sendable {
    func makeInsights(from input: NutritionTrendInsightsInput) -> NutritionTrendInsights?
}

struct NutritionTrendInsightsService: NutritionTrendInsightsServicing, Sendable {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makeInsights(from input: NutritionTrendInsightsInput) -> NutritionTrendInsights? {
        let endDate = calendar.startOfDay(for: input.referenceDate)
        guard let recentStart = calendar.date(byAdding: .day, value: -(input.windowDays - 1), to: endDate) else {
            return nil
        }

        let recentEntries = input.mealEntries.filter { entry in
            let day = calendar.startOfDay(for: entry.loggedAt)
            return day >= recentStart && day <= endDate
        }
        let recentByDay = dailyTotals(for: recentEntries)
        guard !recentByDay.isEmpty else { return nil }

        let previousEnd = calendar.date(byAdding: .day, value: -1, to: recentStart) ?? recentStart
        let previousStart = calendar.date(byAdding: .day, value: -input.windowDays + 1, to: previousEnd) ?? previousEnd
        let previousEntries = input.mealEntries.filter { entry in
            let day = calendar.startOfDay(for: entry.loggedAt)
            return day >= previousStart && day <= previousEnd
        }
        let previousByDay = dailyTotals(for: previousEntries)
        let recentAverage = averageCalories(in: recentByDay)
        let previousAverage = previousByDay.isEmpty ? nil : averageCalories(in: previousByDay)

        return NutritionTrendInsights(
            recentAverageCalories: recentAverage,
            previousAverageCalories: previousAverage,
            calorieDirection: direction(current: recentAverage, previous: previousAverage),
            recentAverageProteinGrams: average(
                recentByDay,
                keyPath: \.proteinGrams
            ),
            recentAverageCarbohydrateGrams: average(
                recentByDay,
                keyPath: \.carbohydrateGrams
            ),
            recentAverageFatGrams: average(recentByDay, keyPath: \.fatGrams),
            recentAverageFiberGrams: average(recentByDay, keyPath: \.fiberGrams),
            loggedDays: recentByDay.count,
            expectedDays: input.windowDays,
            dailyPoints: recentByDay.sorted { $0.date < $1.date },
            target: input.target
        )
    }

    private func dailyTotals(for entries: [MealEntry]) -> [NutritionTrendInsights.DailyPoint] {
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.loggedAt) }
        return grouped.map { date, entries in
            let totals = entries.reduce(into: NutritionAmounts()) { result, entry in
                result.calories += entry.nutrition.calories
                result.proteinGrams += entry.nutrition.proteinGrams
                result.carbohydrateGrams += entry.nutrition.carbohydrateGrams
                result.fatGrams += entry.nutrition.fatGrams
                result.fiberGrams += entry.nutrition.fiberGrams
            }
            return NutritionTrendInsights.DailyPoint(
                date: date,
                calories: Double(totals.calories),
                proteinGrams: totals.proteinGrams,
                carbohydrateGrams: totals.carbohydrateGrams,
                fatGrams: totals.fatGrams,
                fiberGrams: totals.fiberGrams
            )
        }
    }

    private func averageCalories(in points: [NutritionTrendInsights.DailyPoint]) -> Double {
        average(points, keyPath: \.calories)
    }

    private func average<T: BinaryFloatingPoint>(
        _ points: [NutritionTrendInsights.DailyPoint],
        keyPath: KeyPath<NutritionTrendInsights.DailyPoint, T>
    ) -> Double {
        guard !points.isEmpty else { return 0 }
        return points.map { Double($0[keyPath: keyPath]) }.reduce(0, +) / Double(points.count)
    }

    private func direction(current: Double, previous: Double?) -> NutritionTrendInsights.Direction {
        guard let previous else { return .steady }
        let difference = current - previous
        if abs(difference) < 75 { return .steady }
        return difference > 0 ? .rising : .falling
    }
}
