import Foundation

protocol HabitAdherenceServicing {
    func buildSummary(from snapshot: HabitAdherenceSnapshot) -> HabitAdherenceSummary
}

struct HabitAdherenceService: HabitAdherenceServicing, Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func buildSummary(from snapshot: HabitAdherenceSnapshot) -> HabitAdherenceSummary {
        let mealDays = countedDays(
            entries: snapshot.mealEntries.map(\.loggedAt),
            windowDays: snapshot.mealWindowDays,
            referenceDate: snapshot.referenceDate
        )
        let checkInWeeks = countedWeeks(
            entries: snapshot.weightLogs.map(\.recordedAt),
            windowDays: snapshot.checkInWindowDays,
            referenceDate: snapshot.referenceDate
        )
        let mealExpected = max(snapshot.mealWindowDays, 1)
        let checkInExpected = max(numberOfWeeks(in: snapshot.checkInWindowDays), 1)

        return HabitAdherenceSummary(
            mealLoggingStreakDays: streakDays(
                entries: snapshot.mealEntries.map(\.loggedAt),
                referenceDate: snapshot.referenceDate
            ),
            checkInStreakWeeks: streakWeeks(
                entries: snapshot.weightLogs.map(\.recordedAt),
                referenceDate: snapshot.referenceDate
            ),
            mealCoverageRatio: Double(mealDays.count) / Double(mealExpected),
            checkInCoverageRatio: Double(checkInWeeks.count) / Double(checkInExpected),
            mealDaysLogged: mealDays.count,
            mealDaysExpected: mealExpected,
            checkInWeeksLogged: checkInWeeks.count,
            checkInWeeksExpected: checkInExpected,
            latestMealEntryDate: snapshot.mealEntries.map(\.loggedAt).max(),
            latestCheckInDate: snapshot.weightLogs.map(\.recordedAt).max()
        )
    }

    private func countedDays(entries: [Date], windowDays: Int, referenceDate: Date) -> Set<Date> {
        let startDate = calendar.date(byAdding: .day, value: -max(windowDays - 1, 0), to: referenceDate) ?? referenceDate
        let interval = DateInterval(start: calendar.startOfDay(for: startDate), end: calendar.startOfDay(for: referenceDate).addingTimeInterval(60 * 60 * 24))
        return Set(entries.compactMap { date in
            guard interval.contains(date) else { return nil }
            return calendar.startOfDay(for: date)
        })
    }

    private func countedWeeks(entries: [Date], windowDays: Int, referenceDate: Date) -> Set<Date> {
        let startDate = calendar.date(byAdding: .day, value: -max(windowDays - 1, 0), to: referenceDate) ?? referenceDate
        let interval = DateInterval(
            start: calendar.startOfDay(for: startDate),
            end: calendar.startOfDay(for: referenceDate).addingTimeInterval(60 * 60 * 24)
        )

        return Set(entries.compactMap { date in
            guard interval.contains(date),
                  let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else {
                return nil
            }
            return weekStart
        })
    }

    private func numberOfWeeks(in windowDays: Int) -> Int {
        Int(ceil(Double(max(windowDays, 1)) / 7.0))
    }

    private func streakDays(entries: [Date], referenceDate: Date) -> Int {
        let dates = Set(entries.map { calendar.startOfDay(for: $0) })
        var current = calendar.startOfDay(for: referenceDate)
        var count = 0

        while dates.contains(current) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = previous
        }

        return count
    }

    private func streakWeeks(entries: [Date], referenceDate: Date) -> Int {
        let weeks = Set(entries.compactMap { calendar.dateInterval(of: .weekOfYear, for: $0)?.start })
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start else {
            return 0
        }

        var current = currentWeek
        var count = 0

        while weeks.contains(current) {
            count += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: current) else { break }
            current = previous
        }

        return count
    }
}
