import Foundation
import SwiftData

@MainActor
final class SwiftDataUserProfileRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchProfile() throws -> StoredUserProfile? {
        try modelContext.fetch(FetchDescriptor<StoredUserProfile>()).first
    }

    func replaceProfile(_ profile: StoredUserProfile) throws {
        let existingProfiles = try modelContext.fetch(FetchDescriptor<StoredUserProfile>())
        existingProfiles.forEach { modelContext.delete($0) }

        modelContext.insert(profile)
        try modelContext.save()
    }
}
