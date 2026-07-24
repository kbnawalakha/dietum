import Foundation
import SwiftData

@MainActor
final class SwiftDataMealPhotoMetadataRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchMealPhotoMetadata(id: UUID) async throws -> PhotoMetadata? {
        let metadata = try modelContext.fetch(FetchDescriptor<StoredMealPhotoMetadata>())
        return metadata.first(where: { $0.id == id })?.photoMetadata
    }

    func saveMealPhotoMetadata(_ photoMetadata: PhotoMetadata) async throws {
        let existingMetadata = try modelContext.fetch(FetchDescriptor<StoredMealPhotoMetadata>())
        existingMetadata
            .filter { $0.id == photoMetadata.id }
            .forEach { modelContext.delete($0) }

        modelContext.insert(StoredMealPhotoMetadata(photoMetadata))
        try modelContext.save()
    }

    func deleteMealPhotoMetadata(id: UUID) async throws {
        let existingMetadata = try modelContext.fetch(FetchDescriptor<StoredMealPhotoMetadata>())
        existingMetadata
            .filter { $0.id == id }
            .forEach { modelContext.delete($0) }

        try modelContext.save()
    }
}
