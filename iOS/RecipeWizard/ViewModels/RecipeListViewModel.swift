import SwiftUI
import SwiftData

@Observable
final class RecipeListViewModel {
    var searchText = ""
    var sortOrder: SortOrder = .newest
    var isAddingURL = false
    var pendingURL = ""
    var isExtracting = false
    var extractionStage = ""
    var extractionError: String?

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A–Z"
    }

    // MARK: - Sync from API

    @MainActor
    func syncRecipesFromAPI(context: ModelContext) async {
        do {
            let serverRecipes = try await RecipeAPIService.shared.fetchUserRecipes()
            for response in serverRecipes {
                let sourceURL = response.sourceURL
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
            let sourceURL = response.sourceURL
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

    // MARK: - Manual URL extraction

    @MainActor
    func extractRecipe(from url: String, context: ModelContext) async {
        isExtracting = true
        extractionError = nil

        let stages = ["Fetching video…", "Reading captions…", "Extracting with AI…"]
        for stage in stages {
            extractionStage = stage
            try? await Task.sleep(for: .milliseconds(800))
        }

        do {
            let response = try await RecipeAPIService.shared.extractRecipe(from: url)
            let recipe = Recipe(from: response)
            context.insert(recipe)
            try context.save()
            isAddingURL = false
            pendingURL = ""
        } catch APIError.unauthorized {
            AuthService.shared.signOut()
        } catch {
            extractionError = error.localizedDescription
        }

        isExtracting = false
        extractionStage = ""
    }
}
