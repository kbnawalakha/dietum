import Foundation
import SwiftData

@MainActor
final class SwiftDataProgressPhotoRepository: ProgressPhotoRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchProgressPhotos(in dateInterval: DateInterval) async throws -> [ProgressPhotoMetadata] {
        let storedPhotos = try modelContext.fetch(FetchDescriptor<StoredProgressPhotoMetadata>())
        return storedPhotos
            .map(\.progressPhotoMetadata)
            .filter { dateInterval.contains($0.capturedAt) }
            .sorted { $0.capturedAt > $1.capturedAt }
    }

    func saveProgressPhoto(_ photo: ProgressPhotoMetadata) async throws {
        let existingPhotos = try modelContext.fetch(FetchDescriptor<StoredProgressPhotoMetadata>())
        existingPhotos
            .filter { $0.id == photo.id }
            .forEach { modelContext.delete($0) }

        modelContext.insert(StoredProgressPhotoMetadata(photo))
        try modelContext.save()
    }

    func deleteProgressPhoto(id: ProgressPhotoMetadata.ID) async throws {
        let existingPhotos = try modelContext.fetch(FetchDescriptor<StoredProgressPhotoMetadata>())
        existingPhotos
            .filter { $0.id == id }
            .forEach { modelContext.delete($0) }

        try modelContext.save()
    }
}
