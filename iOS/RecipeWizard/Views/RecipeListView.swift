import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var auth
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var viewModel = RecipeListViewModel()
    @State private var appearedCards: Set<UUID> = []
    @State private var iconFloat: CGFloat = 0
    @State private var showingSettings = false
    @FocusState private var searchFocused: Bool

    private var firstName: String {
        auth.currentUser?.name
            .components(separatedBy: " ")
            .first ?? "there"
    }

    private var filteredRecipes: [Recipe] {
        var result = recipes

        // Apply category filter first
        if viewModel.selectedCategory != .all {
            result = result.filter { viewModel.selectedCategory.matches($0) }
        }

        // Then apply text search
        if !viewModel.searchText.isEmpty {
            let q = viewModel.searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.tags.contains(where: { $0.lowercased().contains(q) })
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        searchBar
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

                        if !recipes.isEmpty {
                            categoryStrip
                                .padding(.top, 16)
                        }

                        if recipes.isEmpty {
                            emptyState
                                .padding(.top, 40)
                        } else {
                            recipeSection
                                .padding(.top, 28)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .onTapGesture { searchFocused = false }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(auth)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await viewModel.syncRecipesFromAPI(context: context) }
            viewModel.processPendingRecipes(context: context)
        }
        .task {
            await viewModel.syncRecipesFromAPI(context: context)
            viewModel.processPendingRecipes(context: context)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Hello, \(firstName)!")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("What would you like to cook?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.cardWhite)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.07), radius: 8, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search for recipes...", text: $viewModel.searchText)
                .font(.system(size: 15, design: .rounded))
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFocused = false }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(AppTheme.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
    }

    // MARK: - Recipe Section

    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(viewModel.selectedCategory == .all ? "My Recipes" : viewModel.selectedCategory.rawValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer()
                if filteredRecipes.count != recipes.count {
                    Text("\(filteredRecipes.count) recipe\(filteredRecipes.count == 1 ? "" : "s")")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)

            if filteredRecipes.isEmpty {
                noResultsState
            } else {
                recipeGrid
            }
        }
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Text(viewModel.selectedCategory.icon)
                .font(.system(size: 44))
            Text("No \(viewModel.selectedCategory.rawValue.lowercased()) recipes yet")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            Text("Share a recipe video to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Category Strip

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(viewModel.availableCategories(from: recipes), id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        withAnimation(AppTheme.springBouncy) {
                            viewModel.selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    private var recipeGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 14
        ) {
            ForEach(Array(filteredRecipes.enumerated()), id: \.element.id) { index, recipe in
                NavigationLink(value: recipe) {
                    RecipeCardView(recipe: recipe)
                }
                .buttonStyle(PressAnimationButtonStyle())
                .opacity(appearedCards.contains(recipe.id) ? 1 : 0)
                .offset(y: appearedCards.contains(recipe.id) ? 0 : 16)
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation {
                            context.delete(recipe)
                        }
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                }
                .onAppear {
                    guard !appearedCards.contains(recipe.id) else { return }
                    withAnimation(
                        .spring(response: 0.46, dampingFraction: 0.82)
                        .delay(Double(min(index, 9)) * 0.055)
                    ) {
                        appearedCards.insert(recipe.id)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(AppTheme.orange.opacity(0.10))
                    .frame(width: 150, height: 150)
                Circle()
                    .fill(AppTheme.orange.opacity(0.15))
                    .frame(width: 108, height: 108)
                Image(systemName: "fork.knife")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.orange)
            }
            .offset(y: iconFloat)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    iconFloat = -10
                }
            }

            Spacer().frame(height: 32)

            VStack(spacing: 8) {
                Text("No recipes yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("Share a TikTok or Instagram Reel\nto save your first recipe.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .lineSpacing(3)
            }

        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}

// MARK: - Settings Sheet

private struct SettingsView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    // Profile header
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(initials)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.orange)
                        }
                        VStack(spacing: 4) {
                            if let name = auth.currentUser?.name, !name.isEmpty {
                                Text(name)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                            }
                            if let email = auth.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)

                    Divider().opacity(0.4).padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            iconColor: .red,
                            label: "Sign Out"
                        ) {
                            showSignOutConfirm = true
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(AppTheme.warmCanvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("Sign out of Recipe Wizard AI?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    auth.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var initials: String {
        guard let name = auth.currentUser?.name else { return "?" }
        return name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }
}

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                Text(label)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.cardWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let category: RecipeListViewModel.RecipeCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.icon)
                    .font(.system(size: 15))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    Capsule()
                        .fill(AppTheme.orange)
                        .shadow(color: AppTheme.orange.opacity(0.35), radius: 8, y: 3)
                } else {
                    Capsule()
                        .fill(AppTheme.cardWhite)
                        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                }
            }
            .scaleEffect(isSelected ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
