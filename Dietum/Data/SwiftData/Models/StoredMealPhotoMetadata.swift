import Foundation
import SwiftData

@Model
final class StoredMealPhotoMetadata {
    @Attribute(.unique) var id: UUID
    var storageIdentifier: String
    var capturedAt: Date

    init(_ photoMetadata: PhotoMetadata) {
        self.id = photoMetadata.id
        self.storageIdentifier = photoMetadata.storageIdentifier
        self.capturedAt = photoMetadata.capturedAt
    }

    var photoMetadata: PhotoMetadata {
        PhotoMetadata(
            id: id,
            storageIdentifier: storageIdentifier,
            capturedAt: capturedAt
        )
    }
}
