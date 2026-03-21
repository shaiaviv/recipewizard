import SwiftUI

struct ShareView: View {
    let urlString: String?
    let onDismiss: () -> Void

    @State private var stage: ExtractionStage = .idle
    @State private var errorMessage: String?

    enum ExtractionStage {
        case idle
        case fetchingVideo
        case readingCaption
        case extractingWithAI
        case saving
        case done
        case failed

        var label: String {
            switch self {
            case .idle: return "Starting…"
            case .fetchingVideo: return "Fetching video…"
            case .readingCaption: return "Reading captions…"
            case .extractingWithAI: return "Extracting recipe with AI…"
            case .saving: return "Saving to your recipe book…"
            case .done: return "Saved!"
            case .failed: return "Extraction failed"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let url = urlString {
                    Text(url)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .padding(.horizontal)
                }

                switch stage {
                case .done:
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.green)
                        Text("Recipe saved!")
                            .font(.headline)
                        Text("Open RecipeWizard to view it.")
                            .foregroundStyle(.secondary)
                    }
                case .failed:
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.orange)
                        Text("Extraction failed")
                            .font(.headline)
                        if let err = errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                default:
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.4)
                        Text(stage.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("RecipeWizard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(stage == .done ? "Done" : "Cancel") {
                        onDismiss()
                    }
                }
            }
        }
        .task {
            guard let url = urlString else {
                stage = .failed
                errorMessage = "No URL found in the shared content."
                return
            }
            await runExtraction(url: url)
        }
    }

    // MARK: - Extraction Pipeline

    private func runExtraction(url: String) async {
        let stages: [ExtractionStage] = [.fetchingVideo, .readingCaption, .extractingWithAI, .saving]

        // Animate through stages while the API call runs
        let extractionTask = Task {
            try await RecipeAPIService.shared.extractRecipe(from: url)
        }

        for s in stages.dropLast() {
            stage = s
            try? await Task.sleep(for: .seconds(1))
        }

        do {
            let response = try await extractionTask.value
            stage = .saving
            savePendingRecipe(response)
            try? await Task.sleep(for: .milliseconds(600))
            stage = .done
            try? await Task.sleep(for: .seconds(1.2))
            onDismiss()
        } catch APIError.unauthorized {
            stage = .failed
            errorMessage = "Sign in to RecipeWizard first, then try sharing again."
        } catch {
            stage = .failed
            errorMessage = error.localizedDescription
        }
    }

    private func savePendingRecipe(_ response: RecipeResponse) {
        guard let defaults = UserDefaults(suiteName: SharedConstants.appGroupID) else { return }
        var pending = defaults.array(forKey: SharedConstants.pendingRecipesKey) as? [Data] ?? []
        if let encoded = try? JSONEncoder().encode(response) {
            pending.append(encoded)
        }
        defaults.set(pending, forKey: SharedConstants.pendingRecipesKey)
    }
}
