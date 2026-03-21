import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var viewModel = RecipeListViewModel()

    private var filteredRecipes: [Recipe] {
        guard !viewModel.searchText.isEmpty else { return recipes }
        let q = viewModel.searchText.lowercased()
        return recipes.filter {
            $0.title.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    emptyState
                } else {
                    recipeGrid
                }
            }
            .navigationTitle("RecipeWizard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isAddingURL = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search recipes…")
            .sheet(isPresented: $viewModel.isAddingURL) {
                AddRecipeView(viewModel: viewModel)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.processPendingRecipes(context: context)
        }
        .task {
            viewModel.processPendingRecipes(context: context)
        }
    }

    private var recipeGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink(value: recipe) {
                        RecipeCardView(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No recipes yet")
                .font(.title2.weight(.semibold))
            Text("Share a TikTok or Instagram Reel to\nadd your first recipe.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Paste a URL") {
                viewModel.isAddingURL = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
