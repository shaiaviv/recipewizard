import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Refined charcoal background
            LinearGradient(
                colors: [
                    Color(red: 0.067, green: 0.059, blue: 0.051),
                    Color(red: 0.098, green: 0.090, blue: 0.082),
                    Color(red: 0.130, green: 0.118, blue: 0.106)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Warm ambient glow behind the icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.terracotta.opacity(0.22), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(y: -80)
                .blur(radius: 24)

            VStack(spacing: 0) {
                Spacer()

                // Logo + tagline
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.terracotta.opacity(0.16))
                            .frame(width: 118, height: 118)

                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 74))
                            .foregroundStyle(AppTheme.terracotta)
                    }
                    .scaleEffect(appeared ? 1.0 : 0.65)
                    .opacity(appeared ? 1.0 : 0.0)

                    VStack(spacing: 8) {
                        Text("Recipe Wizard AI")
                            .font(.custom("Didot-Bold", size: 36))
                            .foregroundStyle(.white)
                            .tracking(0.5)

                        Text("Save recipes from TikTok\nand Instagram.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.48))
                            .multilineTextAlignment(.center)
                    }
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : 10)
                }

                Spacer()

                // Sign-in area
                VStack(spacing: 14) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(height: 50)
                    } else {
                        GoogleSignInButton(action: handleSignIn)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1.0 : 0.0)
                .offset(y: appeared ? 0 : 22)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.68, dampingFraction: 0.72).delay(0.1)) {
                appeared = true
            }
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
