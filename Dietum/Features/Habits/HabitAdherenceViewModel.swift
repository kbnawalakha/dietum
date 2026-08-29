import Foundation
import Combine

@MainActor
final class HabitAdherenceViewModel: ObservableObject {
    private let mealRepository: MealEntryRepository
    private let weightLogRepository: WeightLogRepository
    private let service: HabitAdherenceServicing
    private let calendar: Calendar

    @Published var state: HabitAdherenceLoadingState = .idle

    init(
        mealRepository: MealEntryRepository,
        weightLogRepository: WeightLogRepository,
        service: HabitAdherenceServicing = HabitAdherenceService(),
        calendar: Calendar = .current
    ) {
        self.mealRepository = mealRepository
        self.weightLogRepository = weightLogRepository
        self.service = service
        self.calendar = calendar
    }

    func load(referenceDate: Date = Date()) async {
        state = .loading
        do {
            let mealWindow = DateInterval(
                start: calendar.date(byAdding: .day, value: -6, to: referenceDate) ?? referenceDate,
                end: referenceDate
            )
            let checkInWindow = DateInterval(
                start: calendar.date(byAdding: .day, value: -27, to: referenceDate) ?? referenceDate,
                end: referenceDate
            )

            let mealEntries = try await mealRepository.fetchMealEntries(in: mealWindow)
            let weightLogs = try await weightLogRepository.fetchWeightLogs(in: checkInWindow)
            let snapshot = HabitAdherenceSnapshot(
                mealEntries: mealEntries,
                weightLogs: weightLogs,
                referenceDate: referenceDate
            )
            let summary = service.buildSummary(from: snapshot)

            if snapshot.mealEntries.isEmpty, snapshot.weightLogs.isEmpty {
                state = .empty
            } else {
                state = .loaded(summary)
            }
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func cards(for summary: HabitAdherenceSummary) -> [HabitSummaryCard] {
        [
            HabitSummaryCard(
                kind: .streak,
                title: "Meal streak",
                value: formatStreak(summary.mealLoggingStreakDays),
                detail: summary.latestMealEntryDate.map { "Last meal entry \(formatted(date: $0))" } ?? "No meal logs yet"
            ),
            HabitSummaryCard(
                kind: .coverage,
                title: "Meal coverage",
                value: "\(summary.mealCoveragePercent)%",
                detail: "\(summary.mealDaysLogged) of \(summary.mealDaysExpected) days logged"
            ),
            HabitSummaryCard(
                kind: .consistency,
                title: "Check-in streak",
                value: formatStreak(summary.checkInStreakDays),
                detail: summary.latestCheckInDate.map { "Last check-in \(formatted(date: $0))" } ?? "No check-ins yet"
            ),
            HabitSummaryCard(
                kind: .coverage,
                title: "Check-in coverage",
                value: "\(summary.checkInCoveragePercent)%",
                detail: "\(summary.checkInWeeksLogged) of \(summary.checkInWeeksExpected) weeks logged"
            )
        ]
    }

    func subtitle(for summary: HabitAdherenceSummary) -> String {
        if summary.mealLoggingStreakDays == 0 && summary.checkInStreakDays == 0 {
            return "Keep logging meals and check-ins to build momentum."
        }

        return "Consistency is strongest when meals and check-ins stay on a rhythm."
    }

    private func formatStreak(_ count: Int) -> String {
        count == 1 ? "1 day" : "\(count) days"
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
