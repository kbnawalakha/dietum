import Foundation
import SwiftData

@Model
final class StoredProgressPhotoMetadata {
    @Attribute(.unique) var id: UUID
    var capturedAt: Date
    var angleRawValue: String
    var photoMetadataData: Data
    var notes: String?

    init(_ progressPhoto: ProgressPhotoMetadata) {
        self.id = progressPhoto.id
        self.capturedAt = progressPhoto.capturedAt
        self.angleRawValue = progressPhoto.angle.rawValue
        self.photoMetadataData = Self.encode(progressPhoto.photo) ?? Data()
        self.notes = progressPhoto.notes
    }

    var progressPhotoMetadata: ProgressPhotoMetadata {
        ProgressPhotoMetadata(
            id: id,
            capturedAt: capturedAt,
            angle: ProgressPhotoAngle(rawValue: angleRawValue) ?? .front,
            photo: Self.decode(PhotoMetadata.self, from: photoMetadataData) ?? PhotoMetadata(storageIdentifier: "progress-photo-unknown", capturedAt: capturedAt),
            notes: notes
        )
    }
}

private extension StoredProgressPhotoMetadata {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else {
            return nil
        }

        return try? JSONDecoder().decode(type, from: data)
    }
}
