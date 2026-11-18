import Foundation

struct IndianRecipeNutrition: Codable, Hashable, Sendable {
    let id: String
    let name: String
    let servingUnit: String
    let per100Nutrition: NutritionAmounts
}

protocol IndianRecipeCatalog: Sendable {
    func match(for query: String) -> IndianRecipeNutrition?
}

struct BundledIndianRecipeCatalog: IndianRecipeCatalog {
    private let recipes: [IndianRecipeNutrition]

    init() {
        guard let url = Bundle.main.url(forResource: "indb_recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let recipes = try? JSONDecoder().decode([IndianRecipeNutrition].self, from: data) else {
            self.recipes = []
            return
        }
        self.recipes = recipes
    }

    init(recipes: [IndianRecipeNutrition]) {
        self.recipes = recipes
    }

    func match(for query: String) -> IndianRecipeNutrition? {
        let normalizedQuery = Self.normalize(query)
        guard !normalizedQuery.isEmpty else {
            return nil
        }

        let queryTokens = Set(normalizedQuery.split(separator: " ").map(String.init))
        return recipes
            .compactMap { recipe -> (IndianRecipeNutrition, Int)? in
                let normalizedName = Self.normalize(recipe.name)
                let nameTokens = Set(normalizedName.split(separator: " ").map(String.init))

                if normalizedName == normalizedQuery {
                    return (recipe, 100)
                }
                if normalizedName.contains(normalizedQuery) {
                    return (recipe, 80)
                }
                guard queryTokens.count > 1, queryTokens.isSubset(of: nameTokens) else {
                    return nil
                }
                return (recipe, 60)
            }
            .sorted { left, right in
                if left.1 != right.1 {
                    return left.1 > right.1
                }
                return left.0.name < right.0.name
            }
            .first?.0
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9 ]", with: " ", options: .regularExpression)
            .split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
            .joined(separator: " ")
    }
}
