import Foundation

protocol UserProfileRepository {
    func fetchUserProfile() async throws -> UserProfile?
    func saveUserProfile(_ profile: UserProfile) async throws
}

protocol NutritionTargetRepository {
    func fetchActiveNutritionTarget() async throws -> NutritionTarget?
    func saveNutritionTarget(_ target: NutritionTarget) async throws
}

protocol MealEntryRepository {
    func fetchMealEntries(in dateInterval: DateInterval) async throws -> [MealEntry]
    func saveMealEntry(_ entry: MealEntry) async throws
    func deleteMealEntry(id: MealEntry.ID) async throws
}

protocol WeightLogRepository {
    func fetchWeightLogs(in dateInterval: DateInterval) async throws -> [WeightLog]
    func saveWeightLog(_ log: WeightLog) async throws
    func deleteWeightLog(id: WeightLog.ID) async throws
}

protocol ProgressPhotoRepository {
    func fetchProgressPhotos(in dateInterval: DateInterval) async throws -> [ProgressPhotoMetadata]
    func saveProgressPhoto(_ photo: ProgressPhotoMetadata) async throws
    func deleteProgressPhoto(id: ProgressPhotoMetadata.ID) async throws
}
