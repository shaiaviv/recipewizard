import SwiftUI
import SwiftData

struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var recipe: Recipe

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Recipe name", text: $recipe.title)
                }

                Section("Details") {
                    LabeledContent("Cook time (min)") {
                        TextField("", value: $recipe.cookTimeMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Prep time (min)") {
                        TextField("", value: $recipe.prepTimeMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Servings") {
                        TextField("", value: $recipe.servings, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Difficulty", selection: $recipe.difficulty) {
                        Text("—").tag(String?.none)
                        Text("Easy").tag(String?("easy"))
                        Text("Medium").tag(String?("medium"))
                        Text("Hard").tag(String?("hard"))
                    }
                }

                Section("Ingredients") {
                    ForEach(recipe.ingredients.sorted(by: { $0.sortOrder < $1.sortOrder })) { ingredient in
                        TextField("Ingredient", text: Binding(
                            get: { ingredient.displayString },
                            set: { _ in } // read-only in this view; full editing left as future work
                        ))
                    }
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        recipe.updatedAt = Date()
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
