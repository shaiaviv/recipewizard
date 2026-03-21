import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.orange)
                Text("RecipeWizard")
                    .font(.largeTitle.weight(.bold))
                Text("Save recipes from TikTok and Instagram.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .frame(height: 50)
                } else {
                    GoogleSignInButton(action: handleSignIn)
                        .frame(height: 50)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private func handleSignIn() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let vc = scene.windows.first?.rootViewController else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await auth.signIn(presenting: vc)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
