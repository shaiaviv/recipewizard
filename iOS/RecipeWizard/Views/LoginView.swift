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

// MARK: - Custom Google Sign-In Button

private struct GoogleSignInCustomButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Google G badge
                ZStack {
                    Circle()
                        .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                        .frame(width: 32, height: 32)
                    Text("G")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.04))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.orange)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 304)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.995, green: 0.970, blue: 0.935))
                    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
            }
        }
        .buttonStyle(PressAnimationButtonStyle())
    }
}

// MARK: - Login View

struct LoginView: View {
    @Environment(AuthService.self) private var auth
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dark charcoal background
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
                            .font(.custom("Didot-Bold", size: 38))
                            .foregroundStyle(.white)
                            .tracking(0.4)

                        Text("Save recipes from TikTok\n& Instagram — instantly.")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.42))
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
                                .foregroundStyle(.white.opacity(0.50))
                        }
                        .frame(height: 58)
                    } else {
                        GoogleSignInCustomButton(action: handleSignIn)
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
                        .foregroundStyle(.white.opacity(0.20))
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
