import Foundation
import HealthKit

struct ImportedSleepWindow: Equatable, Sendable {
    let bedtime: Date
    let wakeTime: Date

    var duration: TimeInterval {
        max(wakeTime.timeIntervalSince(bedtime), 0)
    }
}

protocol SleepHealthImporting: Sendable {
    func importLatestSleepWindow() async throws -> ImportedSleepWindow
}

enum SleepHealthImportError: LocalizedError, Equatable {
    case unavailable
    case noRecentSleep

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Apple Health sleep data is unavailable on this device."
        case .noRecentSleep:
            return "No recent sleep data was found. Record sleep with Apple Health or Apple Watch, then try again."
        }
    }
}

struct HealthKitSleepService: SleepHealthImporting {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func importLatestSleepWindow() async throws -> ImportedSleepWindow {
        guard HKHealthStore.isHealthDataAvailable(),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw SleepHealthImportError.unavailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: [sleepType])

        let startDate = Calendar.current.date(byAdding: .hour, value: -36, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)],
            limit: HKObjectQueryNoLimit
        )
        let samples = try await descriptor.result(for: healthStore)

        guard let bedtime = samples.map(\.startDate).min(),
              let wakeTime = samples.map(\.endDate).max() else {
            throw SleepHealthImportError.noRecentSleep
        }

        return ImportedSleepWindow(bedtime: bedtime, wakeTime: wakeTime)
    }
}
