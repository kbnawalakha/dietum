import Foundation
import ImageIO
import Vision

enum FoodDataCentralMealAnalysisError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidImage
    case visionFailed
    case noFoodDetected
    case noNutritionData
    case invalidAPIKey
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Meal analysis needs a USDA FoodData Central API key. Add USDA_FOOD_DATA_CENTRAL_API_KEY to the app build settings."
        case .invalidImage:
            return "The meal photo could not be read. Choose another photo or describe the meal."
        case .visionFailed:
            return "Apple Vision could not classify this meal photo. Add a meal description and try again."
        case .noFoodDetected:
            return "No food was identified. Add a description such as chicken, rice, or broccoli and try again."
        case .noNutritionData:
            return "USDA FoodData Central did not return nutrition data for the identified food."
        case .invalidAPIKey:
            return "The USDA FoodData Central API key was rejected. Check USDA_FOOD_DATA_CENTRAL_API_KEY in the app build settings."
        case .requestFailed:
            return "USDA FoodData Central could not be reached. Check your connection and try again."
        }
    }
}
struct FoodDataCentralConfiguration: Sendable, Equatable {
    let apiKey: String

    init(info: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        let value = info["USDAFoodDataCentralAPIKey"] as? String ?? ""
        apiKey = value.contains("$(") ? "" : value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }
}

struct MealIngredientListParser: Sendable {
    static func parse(_ text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: " with ", with: ",")
            .replacingOccurrences(of: " and ", with: ",")

        var seen = Set<String>()
        return normalized
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0 == "\n" || $0 == "•" })
            .map { token in
                token
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}

struct NutritionLabelReading: Sendable, Hashable {
    let name: String
    let servingSizeGrams: Double
    let nutritionPer100Grams: NutritionAmounts
}

struct NutritionLabelReader: Sendable {
    func read(imageData: Data) async throws -> NutritionLabelReading? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw FoodDataCentralMealAnalysisError.invalidImage
        }

        let lines = try await recognizeLines(in: image)
        return Self.parse(lines: lines)
    }

    private func recognizeLines(in image: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: FoodDataCentralMealAnalysisError.visionFailed)
                    return
                }

                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
                } catch {
                    continuation.resume(throwing: FoodDataCentralMealAnalysisError.visionFailed)
                }
            }
        }
    }

    private static func parse(lines: [String]) -> NutritionLabelReading? {
        let normalizedLines = lines.map { $0.replacingOccurrences(of: ",", with: "") }
        guard let servingLine = normalizedLines.first(where: { $0.localizedCaseInsensitiveContains("serving size") }),
              let servingSizeGrams = grams(in: servingLine),
              let calories = value(in: normalizedLines, containing: ["calories"]) else {
            return nil
        }

        let perServing = NutritionAmounts(
            calories: Int(calories.rounded()),
            proteinGrams: value(in: normalizedLines, containing: ["protein"]) ?? 0,
            carbohydrateGrams: value(in: normalizedLines, containing: ["total carbohydrate", "total carb"]) ?? 0,
            fatGrams: value(in: normalizedLines, containing: ["total fat"]) ?? 0,
            fiberGrams: value(in: normalizedLines, containing: ["dietary fiber", "fiber"]) ?? 0,
            micronutrients: NutritionMicronutrients(
                sugarGrams: value(in: normalizedLines, containing: ["total sugars", "sugars"]) ?? 0,
                saturatedFatGrams: value(in: normalizedLines, containing: ["saturated fat"]) ?? 0,
                cholesterolMilligrams: value(in: normalizedLines, containing: ["cholesterol"]) ?? 0,
                sodiumMilligrams: value(in: normalizedLines, containing: ["sodium"]) ?? 0,
                calciumMilligrams: value(in: normalizedLines, containing: ["calcium"]) ?? 0,
                ironMilligrams: value(in: normalizedLines, containing: ["iron"]) ?? 0,
                vitaminAMicrograms: value(in: normalizedLines, containing: ["vitamin a"]) ?? 0,
                vitaminCMilligrams: value(in: normalizedLines, containing: ["vitamin c"]) ?? 0,
                vitaminDMicrograms: value(in: normalizedLines, containing: ["vitamin d"]) ?? 0,
                vitaminEMilligrams: value(in: normalizedLines, containing: ["vitamin e"]) ?? 0,
                vitaminKMicrograms: value(in: normalizedLines, containing: ["vitamin k"]) ?? 0,
                thiaminMilligrams: value(in: normalizedLines, containing: ["thiamin", "thiamine"]) ?? 0,
                riboflavinMilligrams: value(in: normalizedLines, containing: ["riboflavin"]) ?? 0,
                niacinMilligrams: value(in: normalizedLines, containing: ["niacin"]) ?? 0,
                vitaminB6Milligrams: value(in: normalizedLines, containing: ["vitamin b6"]) ?? 0,
                folateMicrograms: value(in: normalizedLines, containing: ["folate"]) ?? 0,
                vitaminB12Micrograms: value(in: normalizedLines, containing: ["vitamin b12"]) ?? 0
            )
        )

        let name = normalizedLines.first(where: {
            !$0.localizedCaseInsensitiveContains("nutrition facts") &&
            !$0.localizedCaseInsensitiveContains("serving size") &&
            !$0.localizedCaseInsensitiveContains("calories")
        }) ?? "Packaged food label"

        return NutritionLabelReading(
            name: name,
            servingSizeGrams: servingSizeGrams,
            nutritionPer100Grams: perServing.scaled(by: 100 / servingSizeGrams)
        )
    }

    private static func value(in lines: [String], containing labels: [String]) -> Double? {
        guard let line = lines.first(where: { line in
            labels.contains { line.localizedCaseInsensitiveContains($0) }
        }) else {
            return nil
        }
        return firstNumber(in: line)
    }

    private static func grams(in line: String) -> Double? {
        firstNumber(in: line, pattern: "\\(([0-9]+(?:\\.[0-9]+)?)\\s*g\\)")
            ?? firstNumber(in: line, pattern: "([0-9]+(?:\\.[0-9]+)?)\\s*g")
    }

    private static func firstNumber(in line: String, pattern: String = "([0-9]+(?:\\.[0-9]+)?)") -> Double? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = expression.firstMatch(in: line, range: range),
              let numberRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        return Double(line[numberRange])
    }
}

struct FoodDataCentralMealAnalysisService: MealFoodDetectionService {
    private let configuration: FoodDataCentralConfiguration
    private let session: URLSession

    init(
        configuration: FoodDataCentralConfiguration = FoodDataCentralConfiguration(),
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session
    }

    func analyzeMeal(description: String, photo: PhotoMetadata?) async throws -> MealFoodDetectionResult {
        let describedQueries = Self.queryTerms(from: description)
        var labelReading: NutritionLabelReading?
        if let imageData = photo?.imageData {
            labelReading = try? await NutritionLabelReader().read(imageData: imageData)
        }

        guard configuration.isConfigured || labelReading != nil else {
            throw FoodDataCentralMealAnalysisError.missingAPIKey
        }

        let photoQueries: [VisionFoodLabel]
        var photoWarning: String?
        if let imageData = photo?.imageData, labelReading == nil {
            do {
                photoQueries = try await VisionFoodClassifier().classify(imageData: imageData)
            } catch {
                guard !describedQueries.isEmpty else {
                    throw error
                }
                photoQueries = []
                photoWarning = "Photo classification was unavailable, so USDA lookup used your description."
            }
        } else {
            photoQueries = []
        }

        let queries = Self.uniqueQueries(describedQueries + photoQueries.map(\.query))
        guard !queries.isEmpty || labelReading != nil else {
            throw FoodDataCentralMealAnalysisError.noFoodDetected
        }

        var detectedFoods: [DetectedMealFood] = labelReading.map { reading in
            [DetectedMealFood(
                name: reading.name,
                confidence: 0.98,
                estimatedWeightGrams: reading.servingSizeGrams,
                servingSizeGrams: reading.servingSizeGrams,
                servings: 1,
                nutritionPer100Grams: reading.nutritionPer100Grams
            )]
        } ?? []

        for query in queries.prefix(6) where configuration.isConfigured {
            guard let food = try await lookup(query: query) else {
                continue
            }

            let visionConfidence = photoQueries.first(where: { $0.query == query })?.confidence
            detectedFoods.append(
                DetectedMealFood(
                    name: food.description,
                    confidence: visionConfidence ?? (describedQueries.contains(query) ? 0.8 : 0.6),
                    estimatedWeightGrams: 100,
                    nutritionPer100Grams: food.nutritionPer100Grams
                )
            )
        }

        guard !detectedFoods.isEmpty else {
            throw FoodDataCentralMealAnalysisError.noNutritionData
        }

        let source = labelReading != nil ? "the nutrition label" : (photoQueries.isEmpty ? "your ingredient list" : "Apple Vision and your ingredient list")
        let warning = photoWarning.map { " \($0)" } ?? ""
        return MealFoodDetectionResult(
            detectedFoods: detectedFoods,
            notes: labelReading != nil ? "The nutrition label was read as one serving. Adjust servings below before saving; values are converted to the shared per-100 g model.\(warning)" : "Nutrition comes from USDA FoodData Central using \(source). Values are per 100 g; adjust each portion before saving. Photo classification estimates food identity, not weight or hidden oils.\(warning)"
        )
    }

    private func lookup(query: String) async throws -> FoodDataCentralMatch? {
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: configuration.apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "5"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy,Branded")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 12

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FoodDataCentralMealAnalysisError.requestFailed
            }

            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw FoodDataCentralMealAnalysisError.invalidAPIKey
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw FoodDataCentralMealAnalysisError.requestFailed
            }

            let result = try JSONDecoder().decode(FoodDataCentralSearchResponse.self, from: data)
            return result.foods.compactMap(FoodDataCentralMatch.init).first
        } catch let error as FoodDataCentralMealAnalysisError {
            throw error
        } catch {
            throw FoodDataCentralMealAnalysisError.requestFailed
        }
    }
}

private struct VisionFoodLabel: Sendable {
    let query: String
    let confidence: Double
}

private struct VisionFoodClassifier: Sendable {
    func classify(imageData: Data) async throws -> [VisionFoodLabel] {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw FoodDataCentralMealAnalysisError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: FoodDataCentralMealAnalysisError.visionFailed)
                    return
                }

                let observations = (request.results as? [VNClassificationObservation] ?? [])
                    .filter { $0.confidence >= 0.05 }
                    .map { VisionFoodLabel(query: Self.normalizedQuery($0.identifier), confidence: Double($0.confidence)) }
                    .filter { !$0.query.isEmpty }
                    .prefix(8)

                guard !observations.isEmpty else {
                    continuation.resume(throwing: FoodDataCentralMealAnalysisError.visionFailed)
                    return
                }

                continuation.resume(returning: Array(observations))
            }

            request.revision = VNClassifyImageRequestRevision2
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
                } catch {
                    continuation.resume(throwing: FoodDataCentralMealAnalysisError.visionFailed)
                }
            }
        }
    }

    private static func normalizedQuery(_ identifier: String) -> String {
        let ignoredLabels = Set([
            "food", "dish", "meal", "cuisine", "plate", "table", "indoor", "restaurant", "produce"
        ])
        let query = identifier
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: ",", maxSplits: 1)
            .first
            .map(String.init) ?? ""
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ignoredLabels.contains(normalized) ? "" : normalized
    }
}

private struct FoodDataCentralSearchResponse: Decodable {
    let foods: [FoodDataCentralFood]
}

private struct FoodDataCentralFood: Decodable {
    let description: String
    let foodNutrients: [FoodDataCentralNutrient]
}

private struct FoodDataCentralNutrient: Decodable {
    let nutrientId: Int?
    let value: Double?
}

private struct FoodDataCentralMatch {
    let description: String
    let nutritionPer100Grams: NutritionAmounts

    init?(food: FoodDataCentralFood) {
        let values = food.foodNutrients.reduce(into: [Int: Double]()) { values, nutrient in
            guard let id = nutrient.nutrientId, let value = nutrient.value else {
                return
            }
            values[id] = value
        }

        guard let calories = values[1008] ?? values[208] else {
            return nil
        }

        description = food.description
        nutritionPer100Grams = NutritionAmounts(
            calories: Int(calories.rounded()),
            proteinGrams: values[1003] ?? values[203] ?? 0,
            carbohydrateGrams: values[1005] ?? values[205] ?? 0,
            fatGrams: values[1004] ?? values[204] ?? 0,
            fiberGrams: values[1079] ?? values[291] ?? 0,
            micronutrients: NutritionMicronutrients(
                sugarGrams: values[2000] ?? 0,
                saturatedFatGrams: values[1258] ?? 0,
                cholesterolMilligrams: values[1253] ?? 0,
                sodiumMilligrams: values[1093] ?? 0,
                potassiumMilligrams: values[1092] ?? 0,
                calciumMilligrams: values[1087] ?? 0,
                ironMilligrams: values[1089] ?? 0,
                magnesiumMilligrams: values[1090] ?? 0,
                phosphorusMilligrams: values[1091] ?? 0,
                zincMilligrams: values[1095] ?? 0,
                vitaminAMicrograms: values[1106] ?? 0,
                vitaminCMilligrams: values[1162] ?? 0,
                vitaminDMicrograms: values[1114] ?? 0,
                vitaminEMilligrams: values[1109] ?? 0,
                vitaminKMicrograms: values[1185] ?? 0,
                thiaminMilligrams: values[1165] ?? 0,
                riboflavinMilligrams: values[1166] ?? 0,
                niacinMilligrams: values[1167] ?? 0,
                vitaminB6Milligrams: values[1175] ?? 0,
                folateMicrograms: values[1177] ?? 0,
                vitaminB12Micrograms: values[1178] ?? 0,
                cholineMilligrams: values[1180] ?? 0
            )
        )
    }
}

private extension FoodDataCentralMealAnalysisService {
    static func queryTerms(from description: String) -> [String] {
        MealIngredientListParser.parse(description)
    }

    static func uniqueQueries(_ queries: [String]) -> [String] {
        var seen = Set<String>()
        return queries.filter { seen.insert($0).inserted }
    }
}
