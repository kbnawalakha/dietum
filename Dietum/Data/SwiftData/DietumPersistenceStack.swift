import Foundation
import SwiftData

enum DietumPersistenceStack {
    static let schema = Schema([
        StoredNutritionTarget.self,
        StoredMealEntry.self,
        StoredMealPhotoMetadata.self,
        StoredUserProfile.self,
        StoredWeightEntry.self,
    ])

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makePreviewContainer() -> ModelContainer {
        do {
            return try makeContainer(inMemory: true)
        } catch {
            fatalError("Failed to create an in-memory Dietum SwiftData container: \(error)")
        }
    }
}
