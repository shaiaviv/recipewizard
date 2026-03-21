import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @State private var showingEdit = false
    @State private var checkedIngredients: Set<UUID> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                if let data = recipe.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Title + review warning
                    VStack(alignment: .leading, spacing: 6) {
                        if recipe.needsReview {
                            Label("AI wasn't certain — please review this recipe", systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Text(recipe.title)
                            .font(.title2.weight(.bold))
                    }

                    // Metadata chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            if let time = recipe.totalTimeMinutes {
                                MetaChip(icon: "clock", text: "\(time) min")
                            }
                            if let servings = recipe.servings {
                                MetaChip(icon: "person.2", text: "\(servings) servings")
                            }
                            if let difficulty = recipe.difficulty {
                                MetaChip(icon: "chart.bar", text: difficulty.capitalized)
                            }
                            MetaChip(
                                icon: recipe.platform == "tiktok" ? "music.note" : "camera",
                                text: recipe.platform.capitalized
                            )
                        }
                    }

                    // Ingredients
                    if !recipe.ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ingredients")
                                .font(.headline)

                            ForEach(recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder })) { ingredient in
                                Button {
                                    if checkedIngredients.contains(ingredient.id) {
                                        checkedIngredients.remove(ingredient.id)
                                    } else {
                                        checkedIngredients.insert(ingredient.id)
                                    }
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: checkedIngredients.contains(ingredient.id)
                                              ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(checkedIngredients.contains(ingredient.id)
                                                             ? .green : .secondary)
                                        Text(ingredient.displayString)
                                            .strikethrough(checkedIngredients.contains(ingredient.id))
                                            .foregroundStyle(checkedIngredients.contains(ingredient.id)
                                                             ? .secondary : .primary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Steps
                    if !recipe.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.headline)

                            ForEach(recipe.steps.sorted(by: { $0.stepNumber < $1.stepNumber })) { step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(step.stepNumber)")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step.instruction)
                                        if let dur = step.durationMinutes {
                                            Label("\(dur) min", systemImage: "timer")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Source link
                    Link(destination: URL(string: recipe.sourceURL)!) {
                        Label("View original on \(recipe.platform.capitalized)", systemImage: "arrow.up.right.square")
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditRecipeView(recipe: recipe)
        }
    }
}

private struct MetaChip: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}
