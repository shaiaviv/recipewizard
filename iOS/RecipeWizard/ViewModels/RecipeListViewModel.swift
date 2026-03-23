import SwiftUI
import SwiftData

@Observable
final class RecipeListViewModel {
    var searchText = ""
    var sortOrder: SortOrder = .newest
    var selectedCategory: RecipeCategory = .all

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A–Z"
    }

    // MARK: - Category Filter

    enum RecipeCategory: String, CaseIterable, Hashable {
        case all       = "All"
        case italian   = "Italian"
        case mexican   = "Mexican"
        case asian     = "Asian"
        case chicken   = "Chicken"
        case seafood   = "Seafood"
        case meat      = "Meat"
        case healthy   = "Healthy"
        case dessert   = "Dessert"
        case breakfast = "Breakfast"
        case soup      = "Soup"

        var icon: String {
            switch self {
            case .all:       return "🍽️"
            case .italian:   return "🍝"
            case .mexican:   return "🌮"
            case .asian:     return "🍜"
            case .chicken:   return "🍗"
            case .seafood:   return "🐟"
            case .meat:      return "🥩"
            case .healthy:   return "🥗"
            case .dessert:   return "🍰"
            case .breakfast: return "🥞"
            case .soup:      return "🥘"
            }
        }

        var keywords: [String] {
            switch self {
            case .all:       return []
            case .italian:   return ["pasta", "pizza", "risotto", "carbonara", "lasagna", "gnocchi", "pesto", "tiramisu", "italian", "linguine", "fettuccine", "spaghetti", "ravioli", "arrabbiata"]
            case .mexican:   return ["taco", "burrito", "enchilada", "salsa", "guacamole", "quesadilla", "fajita", "mexican", "jalapeño", "nacho", "tortilla", "chipotle", "carnitas"]
            case .asian:     return ["ramen", "sushi", "stir fry", "stir-fry", "dumpling", "noodle", "fried rice", "thai", "chinese", "japanese", "korean", "pad thai", "pho", "miso", "teriyaki", "wok", "soy sauce", "bao", "bibimbap", "kimchi", "curry", "szechuan"]
            case .chicken:   return ["chicken", "poultry", "wings", "drumstick"]
            case .seafood:   return ["salmon", "fish", "shrimp", "tuna", "crab", "lobster", "seafood", "cod", "tilapia", "prawn", "scallop", "oyster", "clam", "halibut", "mahi"]
            case .meat:      return ["beef", "steak", "lamb", "pork", "bbq", "burger", "meatball", "meatloaf", "brisket", "ribs", "ground beef", "chorizo", "bacon"]
            case .healthy:   return ["salad", "smoothie", "bowl", "quinoa", "kale", "vegan", "vegetarian", "low carb", "grain", "detox", "green", "avocado", "tofu", "lentil", "chickpea"]
            case .dessert:   return ["cake", "cookie", "brownie", "pie", "dessert", "sweet", "chocolate", "cupcake", "muffin", "pudding", "ice cream", "fudge", "tart", "cheesecake", "macaron"]
            case .breakfast: return ["pancake", "waffle", "egg", "omelette", "breakfast", "brunch", "toast", "bagel", "cereal", "granola", "crepe", "french toast", "benedict"]
            case .soup:      return ["soup", "stew", "chili", "broth", "bisque", "chowder"]
            }
        }

        func matches(_ recipe: Recipe) -> Bool {
            if self == .all { return true }
            let haystack = ([recipe.title] + recipe.tags).joined(separator: " ").lowercased()
            return keywords.contains(where: { haystack.contains($0) })
        }
    }

    /// Returns only categories that have at least one matching recipe (always includes .all).
    func availableCategories(from recipes: [Recipe]) -> [RecipeCategory] {
        RecipeCategory.allCases.filter { category in
            category == .all || recipes.contains(where: { category.matches($0) })
        }
    }

    // MARK: - Sync from API

    @MainActor
    func syncRecipesFromAPI(context: ModelContext) async {
        do {
            let serverRecipes = try await RecipeAPIService.shared.fetchUserRecipes()
            for response in serverRecipes {
                let sourceURL = response.sourceUrl
                let descriptor = FetchDescriptor<Recipe>(
                    predicate: #Predicate { $0.sourceURL == sourceURL }
                )
                let existing = try? context.fetch(descriptor).first
                if existing == nil {
                    let recipe = Recipe(from: response)
                    context.insert(recipe)
                }
            }
            try? context.save()
        } catch APIError.unauthorized {
            AuthService.shared.signOut()
        } catch {
            print("[RecipeListViewModel] API sync failed: \(error)")
        }
    }

    // MARK: - Pending recipes from Share Extension

    @MainActor
    func processPendingRecipes(context: ModelContext) {
        guard let defaults = UserDefaults(suiteName: SharedConstants.appGroupID),
              let pendingData = defaults.array(forKey: SharedConstants.pendingRecipesKey) as? [Data],
              !pendingData.isEmpty
        else { return }

        defaults.removeObject(forKey: SharedConstants.pendingRecipesKey)

        for data in pendingData {
            guard let response = try? JSONDecoder().decode(RecipeResponse.self, from: data) else { continue }
            let sourceURL = response.sourceUrl
            let descriptor = FetchDescriptor<Recipe>(
                predicate: #Predicate { $0.sourceURL == sourceURL }
            )
            let existing = try? context.fetch(descriptor).first
            if existing == nil {
                let recipe = Recipe(from: response)
                context.insert(recipe)
            }
        }

        try? context.save()
    }

}
