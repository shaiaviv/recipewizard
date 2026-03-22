import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var auth
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var viewModel = RecipeListViewModel()
    @State private var appearedCards: Set<Int> = []
    @State private var iconFloat: CGFloat = 0
    @State private var showingSettings = false
    @FocusState private var searchFocused: Bool

    private var firstName: String {
        auth.currentUser?.name
            .components(separatedBy: " ")
            .first ?? "there"
    }

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
            ZStack {
                AppTheme.warmCanvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        searchBar
                            .padding(.top, 20)
                            .padding(.horizontal, 20)

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
            .sheet(isPresented: $viewModel.isAddingURL) {
                AddRecipeView(viewModel: viewModel)
            }
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
            HStack(alignment: .center) {
                Text("My Recipes")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer()

                Button {
                    viewModel.isAddingURL = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.orange)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            recipeGrid
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
                .opacity(appearedCards.contains(index) ? 1 : 0)
                .offset(y: appearedCards.contains(index) ? 0 : 16)
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
                    guard !appearedCards.contains(index) else { return }
                    withAnimation(
                        .spring(response: 0.46, dampingFraction: 0.82)
                        .delay(Double(min(index, 9)) * 0.055)
                    ) {
                        appearedCards.insert(index)
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

            Spacer().frame(height: 32)

            Button {
                viewModel.isAddingURL = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add a Recipe")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(AppTheme.orange)
                .clipShape(Capsule())
                .shadow(color: AppTheme.orange.opacity(0.35), radius: 12, y: 6)
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
                AppTheme.warmCanvas.ignoresSafeArea()

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
