import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: RecipeListViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste a TikTok or Instagram URL")
                        .font(.headline)
                    TextField("https://www.tiktok.com/...", text: $viewModel.pendingURL, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if viewModel.isExtracting {
                    LoadingView(stage: viewModel.extractionStage)
                }

                if let error = viewModel.extractionError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isExtracting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Extract") {
                        Task {
                            await viewModel.extractRecipe(from: viewModel.pendingURL, context: context)
                        }
                    }
                    .disabled(viewModel.pendingURL.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isExtracting)
                }
            }
        }
    }
}
