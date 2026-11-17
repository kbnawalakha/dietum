import Foundation
import HealthKit

struct ImportedSleepWindow: Equatable, Sendable {
    let bedtime: Date
    let sleepStart: Date
    let wakeTime: Date
    let outOfBedTime: Date

    init(
        bedtime: Date,
        sleepStart: Date? = nil,
        wakeTime: Date,
        outOfBedTime: Date? = nil
    ) {
        self.bedtime = bedtime
        self.sleepStart = sleepStart ?? bedtime
        self.wakeTime = wakeTime
        self.outOfBedTime = outOfBedTime ?? wakeTime
    }

    var duration: TimeInterval {
        max(wakeTime.timeIntervalSince(sleepStart), 0)
    }

    var preSleepDoomScrollDuration: TimeInterval {
        max(sleepStart.timeIntervalSince(bedtime), 0)
    }

    var postWakeDoomScrollDuration: TimeInterval {
        max(outOfBedTime.timeIntervalSince(wakeTime), 0)
    }
}

protocol SleepHealthImporting: Sendable {
    func importLatestSleepWindow() async throws -> ImportedSleepWindow

    func importRecentSleepWindows(days: Int) async throws -> [ImportedSleepWindow]
}

extension SleepHealthImporting {
    func importRecentSleepWindows(days: Int) async throws -> [ImportedSleepWindow] {
        [try await importLatestSleepWindow()]
    }
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
        try await importRecentSleepWindows(days: 2).first ?? {
            throw SleepHealthImportError.noRecentSleep
        }()
    }

    func importRecentSleepWindows(days: Int) async throws -> [ImportedSleepWindow] {
        guard HKHealthStore.isHealthDataAvailable(),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw SleepHealthImportError.unavailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: [sleepType])

        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -(max(days, 1) + 1), to: Date()) ?? Date()
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

        let groupedSamples = Dictionary(grouping: samples) { sample in
            let shiftedStart = calendar.date(byAdding: .hour, value: -12, to: sample.startDate) ?? sample.startDate
            return calendar.startOfDay(for: shiftedStart)
        }

        let windows = groupedSamples.values.compactMap { Self.makeSleepWindow(from: $0) }
            .sorted { $0.bedtime > $1.bedtime }

        guard !windows.isEmpty else {
            throw SleepHealthImportError.noRecentSleep
        }

        return windows
    }
}

private extension HealthKitSleepService {
    static func makeSleepWindow(from samples: [HKCategorySample]) -> ImportedSleepWindow? {
        let asleepSamples = samples.filter(isAsleep)
        guard !asleepSamples.isEmpty else {
            return nil
        }

        let inBedSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
        let bedtime = (inBedSamples.map(\.startDate).min() ?? asleepSamples.map(\.startDate).min())
        guard let bedtime,
              let sleepStart = asleepSamples.map(\.startDate).min(),
              let wakeTime = asleepSamples.map(\.endDate).max() else {
            return nil
        }

        let outOfBedTime = inBedSamples.map(\.endDate).max() ?? wakeTime
        return ImportedSleepWindow(
            bedtime: bedtime,
            sleepStart: sleepStart,
            wakeTime: wakeTime,
            outOfBedTime: outOfBedTime
        )
    }

    static func isAsleep(_ sample: HKCategorySample) -> Bool {
        switch sample.value {
        case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
             HKCategoryValueSleepAnalysis.asleepCore.rawValue,
             HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
             HKCategoryValueSleepAnalysis.asleepREM.rawValue:
            return true
        default:
            return false
        }
    }
}
