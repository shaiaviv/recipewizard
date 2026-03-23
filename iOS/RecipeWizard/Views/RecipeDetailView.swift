import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false
    @State private var checkedIngredients: Set<UUID> = []
    @State private var contentAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .foregroundStyle(.red)
                    }
                    Button {
                        showingEdit = true
                    } label: {
                        Text("Edit")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditRecipeView(recipe: recipe)
        }
        .confirmationDialog("Delete \"\(recipe.title)\"?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Recipe", role: .destructive) {
                dismiss()
                context.delete(recipe)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This recipe will be permanently removed.")
        }
        .onAppear {
            withAnimation(AppTheme.springSmooth.delay(0.12)) {
                contentAppeared = true
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        Group {
            if let data = recipe.thumbnailData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppTheme.espresso, Color(red: 0.24, green: 0.16, blue: 0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.22))
                }
            }
        }
        .containerRelativeFrame(.horizontal)
        .frame(height: 320)
        .clipped()
        .overlay(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: .clear,              location: 0.35),
                    .init(color: .black.opacity(0.42), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title + review warning
            VStack(alignment: .leading, spacing: 10) {
                if recipe.needsReview {
                    HStack(spacing: 6) {
                        Label("AI wasn't certain — please review", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.amber)
                        Spacer()
                        Button {
                            recipe.reviewDismissed = true
                            recipe.updatedAt = Date()
                            try? context.save()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.amber.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.amber.opacity(0.12))
                    .clipShape(Capsule())
                }

                Text(recipe.title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
            }

            // Metadata chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let time = recipe.totalTimeMinutes {
                        DetailMetaChip(icon: "clock", text: "\(time) min")
                    }
                    if let servings = recipe.servings {
                        DetailMetaChip(icon: "person.2", text: "\(servings) servings")
                    }
                    if let difficulty = recipe.difficulty {
                        DetailMetaChip(icon: "chart.bar", text: difficulty.capitalized)
                    }
                    DetailMetaChip(
                        icon: recipe.platform == "tiktok" ? "music.note" : "camera.fill",
                        text: recipe.platform.capitalized
                    )
                }
                .padding(.horizontal, 1)
            }

            // Ingredients
            if !recipe.ingredients.isEmpty {
                ingredientsSection
            }

            // Steps
            if !recipe.steps.isEmpty {
                stepsSection
            }

            // Source link
            Link(destination: URL(string: recipe.sourceURL)!) {
                HStack(spacing: 6) {
                    Text("View original on \(recipe.platform.capitalized)")
                    Image(systemName: "arrow.up.right")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.terracotta)
            }
        }
        .padding(20)
        .padding(.bottom, 36)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 14)
        .animation(AppTheme.springSmooth, value: contentAppeared)
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.system(size: 18, weight: .semibold, design: .serif))

            let sorted = recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder })
            VStack(spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, ingredient in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(AppTheme.springBouncy) {
                            if checkedIngredients.contains(ingredient.id) {
                                checkedIngredients.remove(ingredient.id)
                            } else {
                                checkedIngredients.insert(ingredient.id)
                            }
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: checkedIngredients.contains(ingredient.id)
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 19))
                                .foregroundStyle(
                                    checkedIngredients.contains(ingredient.id)
                                    ? AppTheme.terracotta : Color(.tertiaryLabel)
                                )
                                .animation(AppTheme.springBouncy, value: checkedIngredients.contains(ingredient.id))

                            Text(ingredient.displayString)
                                .font(.body)
                                .strikethrough(checkedIngredients.contains(ingredient.id))
                                .foregroundStyle(checkedIngredients.contains(ingredient.id) ? .secondary : .primary)

                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)

                    if index < sorted.count - 1 {
                        Divider()
                            .padding(.leading, 47)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.sectionRadius, style: .continuous))
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.system(size: 18, weight: .semibold, design: .serif))

            ForEach(recipe.steps.sorted(by: { $0.stepNumber < $1.stepNumber })) { step in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.terracotta)
                            .frame(width: 28, height: 28)
                        Text("\(step.stepNumber)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(step.instruction)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        if let dur = step.durationMinutes {
                            Label("\(dur) min", systemImage: "timer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 3)
                }
            }
        }
    }
}

private struct DetailMetaChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }
}
