import SwiftUI
import SwiftData

struct AddRecipeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: RecipeListViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                // URL input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Paste a TikTok or Instagram URL")
                        .font(.system(size: 15, weight: .semibold, design: .serif))

                    TextField("https://www.tiktok.com/...", text: $viewModel.pendingURL, axis: .vertical)
                        .font(.body)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color(.separator).opacity(0.45), lineWidth: 1)
                        )
                }

                if viewModel.isExtracting {
                    LoadingView(stage: viewModel.extractionStage)
                }

                if let error = viewModel.extractionError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    .padding(12)
                    .background(.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Spacer()
            }
            .padding(20)
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
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.terracotta)
                    .disabled(
                        viewModel.pendingURL.trimmingCharacters(in: .whitespaces).isEmpty
                        || viewModel.isExtracting
                    )
                }
            }
        }
    }
}
