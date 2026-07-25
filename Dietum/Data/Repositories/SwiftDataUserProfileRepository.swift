import Foundation
import SwiftData

@MainActor
final class SwiftDataUserProfileRepository: UserProfileRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchUserProfile() async throws -> UserProfile? {
        try modelContext.fetch(FetchDescriptor<StoredUserProfile>()).first?.userProfile
    }

    func saveUserProfile(_ profile: UserProfile) async throws {
        let existingProfiles = try modelContext.fetch(FetchDescriptor<StoredUserProfile>())
        existingProfiles.forEach { modelContext.delete($0) }

        modelContext.insert(StoredUserProfile(profile))
        try modelContext.save()
    }
}
