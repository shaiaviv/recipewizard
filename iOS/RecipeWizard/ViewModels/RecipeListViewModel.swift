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
        case favorites = "Favorites"
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
            case .favorites: return "❤️"
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
            case .favorites: return []
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

        /// Accent color unique to each category
        var color: Color {
            switch self {
            case .all:       return Color(red: 0.97, green: 0.59, blue: 0.19) // brand orange
            case .favorites: return Color(red: 0.96, green: 0.27, blue: 0.40) // warm red
            case .italian:   return Color(red: 0.88, green: 0.24, blue: 0.19) // tomato red
            case .mexican:   return Color(red: 0.20, green: 0.72, blue: 0.35) // guacamole green
            case .asian:     return Color(red: 0.82, green: 0.12, blue: 0.25) // crimson
            case .chicken:   return Color(red: 0.98, green: 0.71, blue: 0.10) // golden yellow
            case .seafood:   return Color(red: 0.08, green: 0.65, blue: 0.79) // ocean teal
            case .meat:      return Color(red: 0.62, green: 0.16, blue: 0.10) // deep burgundy
            case .healthy:   return Color(red: 0.22, green: 0.74, blue: 0.42) // fresh green
            case .dessert:   return Color(red: 0.90, green: 0.27, blue: 0.61) // rose pink
            case .breakfast: return Color(red: 0.98, green: 0.54, blue: 0.10) // warm amber
            case .soup:      return Color(red: 0.76, green: 0.35, blue: 0.08) // clay
            }
        }

        func matches(_ recipe: Recipe) -> Bool {
            switch self {
            case .all:       return true
            case .favorites: return recipe.isFavorited
            default:
                let haystack = ([recipe.title] + recipe.tags).joined(separator: " ").lowercased()
                return keywords.contains(where: { haystack.contains($0) })
            }
        }
    }

    /// Returns only categories that have at least one matching recipe (always includes .all).
    func availableCategories(from recipes: [Recipe]) -> [RecipeCategory] {
        RecipeCategory.allCases.filter { category in
            switch category {
            case .all:       return true
            case .favorites: return recipes.contains(where: { $0.isFavorited })
            default:         return recipes.contains(where: { category.matches($0) })
            }
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
