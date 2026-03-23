import SwiftUI

// MARK: - Pulse Ring

private struct PulseRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.75
    @State private var opacity: Double = 0.55

    var body: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .stroke(AppTheme.orange.opacity(opacity), lineWidth: 1.5)
            .frame(width: 128, height: 128)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.4)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    scale = 2.2
                    opacity = 0
                }
            }
    }
}

// MARK: - App Icon Hero (animated)

private struct AppIconHeroView: View {
    @State private var bobOffset: CGFloat = 0
    @State private var orbit1: Double = 0
    @State private var orbit2: Double = 0
    @State private var shimmer: CGFloat = -140

    var body: some View {
        ZStack {
            // Three expanding pulse rings, staggered
            PulseRing(delay: 0.00)
            PulseRing(delay: 0.80)
            PulseRing(delay: 1.60)

            // Orbit 1 — sparkle, clockwise, 7s
            ZStack {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.orange.opacity(0.80))
                    .offset(y: -86)
            }
            .rotationEffect(.degrees(orbit1))

            // Orbit 2 — amber dot, counter-clockwise, 11s, wider
            ZStack {
                Circle()
                    .fill(AppTheme.amber.opacity(0.85))
                    .frame(width: 6, height: 6)
                    .offset(x: 76)
            }
            .rotationEffect(.degrees(-orbit2))

            // Orbit 3 — tiny white dot, slow clockwise
            ZStack {
                Circle()
                    .fill(.white.opacity(0.50))
                    .frame(width: 4, height: 4)
                    .offset(y: 78)
            }
            .rotationEffect(.degrees(orbit1 * 0.6))

            // Icon image
            Image("AppIconHero")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 114, height: 114)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: AppTheme.orange.opacity(0.55), radius: 28, x: 0, y: 14)
                // Shimmer overlay
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.28),
                                    .clear
                                ],
                                startPoint: UnitPoint(x: shimmer / 140, y: 0),
                                endPoint: UnitPoint(x: (shimmer + 80) / 140, y: 1)
                            )
                        )
                        .allowsHitTesting(false)
                }
        }
        .offset(y: bobOffset)
        .onAppear {
            // Gentle float
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true).delay(0.3)) {
                bobOffset = -11
            }
            // Clockwise orbit
            withAnimation(.linear(duration: 7.0).repeatForever(autoreverses: false).delay(0.4)) {
                orbit1 = 360
            }
            // Counter-clockwise orbit
            withAnimation(.linear(duration: 11.0).repeatForever(autoreverses: false).delay(0.4)) {
                orbit2 = 360
            }
            // Shimmer sweep every 4s
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false).delay(1.2)) {
                shimmer = 140
            }
        }
    }
}

// MARK: - Google Sign-In Button

private struct GoogleSignInButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image("google_g_logo")
                    .resizable()
                    .frame(width: 24, height: 24)

                Text("Sign in with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 0.235, green: 0.255, blue: 0.267))
            }
            .frame(maxWidth: 304)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            }
        }
        .buttonStyle(PressAnimationButtonStyle())
    }
}

// MARK: - Login View

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background matches app-wide light/dark theme
            LinearGradient(
                colors: colorScheme == .dark ? [
                    Color(red: 0.055, green: 0.030, blue: 0.090),
                    Color(red: 0.078, green: 0.048, blue: 0.122),
                    Color(red: 0.105, green: 0.068, blue: 0.158)
                ] : [
                    Color(red: 1.00, green: 0.975, blue: 0.945),
                    Color(red: 0.99, green: 0.945, blue: 0.875),
                    Color(red: 0.97, green: 0.905, blue: 0.800)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Large warm ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.orange.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 270
                    )
                )
                .frame(width: 540, height: 540)
                .offset(y: -120)
                .blur(radius: 18)

            VStack(spacing: 0) {
                Spacer()

                // Brand section
                VStack(spacing: 80) {
                    AppIconHeroView()
                        .scaleEffect(appeared ? 1.0 : 0.55)
                        .opacity(appeared ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.70, dampingFraction: 0.65).delay(0.05),
                            value: appeared
                        )

                    VStack(spacing: 10) {
                        Text("Recipe Wizard AI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Save recipes from TikTok\n& Instagram — instantly.")
                            .font(.system(size: 15))
                            .foregroundStyle(.primary.opacity(0.50))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .opacity(appeared ? 1.0 : 0.0)
                    .offset(y: appeared ? 0 : 14)
                    .animation(
                        .spring(response: 0.58, dampingFraction: 0.80).delay(0.22),
                        value: appeared
                    )
                }

                Spacer()

                // Sign-in section
                VStack(spacing: 18) {
                    if isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(AppTheme.orange)
                            Text("Signing in…")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.50))
                        }
                        .frame(height: 58)
                    } else {
                        GoogleSignInButton(action: handleSignIn)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color(red: 1.0, green: 0.40, blue: 0.40))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }

                    Text("By continuing you agree to our Terms & Privacy Policy.")
                        .font(.system(size: 11))
                        .foregroundStyle(.primary.opacity(0.28))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 44)
                }
                .padding(.bottom, 58)
                .opacity(appeared ? 1.0 : 0.0)
                .offset(y: appeared ? 0 : 26)
                .animation(
                    .spring(response: 0.60, dampingFraction: 0.82).delay(0.36),
                    value: appeared
                )
            }
        }
        .onAppear {
            appeared = true
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
