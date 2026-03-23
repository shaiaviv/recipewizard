import SwiftUI

// MARK: - Design System

enum AppTheme {
    // Bright warm orange (matches Dribbble design)
    static let orange     = Color(red: 0.97, green: 0.59, blue: 0.19)
    static let orangeLight = Color(red: 0.97, green: 0.59, blue: 0.19).opacity(0.12)
    static let amber      = Color(red: 0.83, green: 0.51, blue: 0.063)
    static let espresso   = Color(red: 0.11, green: 0.07, blue: 0.04)

    // Keep terracotta as alias so existing views compile
    static var terracotta: Color { orange }

    /// Light warm peach in light mode, refined charcoal in dark mode (used for toolbars)
    static let warmCanvas = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.09, blue: 0.085, alpha: 1)  // refined charcoal
            : UIColor(red: 0.99, green: 0.96, blue: 0.89, alpha: 1)   // warm peach
    })

    /// White in light mode, elevated charcoal card in dark mode
    static let cardWhite = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.155, green: 0.145, blue: 0.135, alpha: 1) // elevated charcoal card
            : UIColor.white
    })

    static let cardRadius: CGFloat    = 18
    static let sectionRadius: CGFloat = 14

    static func serifFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static var springBouncy: Animation {
        .spring(response: 0.38, dampingFraction: 0.70)
    }
    static var springSmooth: Animation {
        .spring(response: 0.52, dampingFraction: 0.86)
    }
}

// MARK: - App Background

/// Multi-stop gradient with floating ambient light accents.
/// Blobs are in .overlay() so they never affect layout sizing.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color(red: 0.067, green: 0.059, blue: 0.051), // deep charcoal
                Color(red: 0.098, green: 0.090, blue: 0.082), // mid charcoal
                Color(red: 0.130, green: 0.118, blue: 0.106)  // lifted charcoal
            ] : [
                Color(red: 1.00, green: 0.975, blue: 0.945), // warm ivory
                Color(red: 0.99, green: 0.945, blue: 0.875), // golden cream
                Color(red: 0.97, green: 0.905, blue: 0.800)  // apricot
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        // Blobs are overlays — they never contribute to layout size
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.orange.opacity(colorScheme == .dark ? 0.16 : 0.26), .clear],
                        center: .center, startRadius: 0, endRadius: 200
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: 120, y: -140)
                .blur(radius: colorScheme == .dark ? 40 : 28)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (colorScheme == .dark
                                ? Color(red: 0.55, green: 0.28, blue: 0.04)  // dark amber
                                : AppTheme.amber
                            ).opacity(colorScheme == .dark ? 0.22 : 0.12),
                            .clear
                        ],
                        center: .center, startRadius: 0, endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: -100, y: 80)
                .blur(radius: 50)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct PressAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

// MARK: - Favorite Button

struct FavoriteButton: View {
    let recipe: Recipe
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        Button {
            recipe.isFavorited = !(recipe.isFavorited == true)
            // Two-phase pump: quick snap up, then spring settle
            withAnimation(.spring(response: 0.20, dampingFraction: 0.42)) {
                heartScale = 1.45
            }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.68).delay(0.14)) {
                heartScale = 1.0
            }
        } label: {
            let favorited = recipe.isFavorited == true
            Image(systemName: favorited ? "heart.fill" : "heart")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(favorited
                    ? Color(red: 0.96, green: 0.27, blue: 0.40)
                    : .white)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                .scaleEffect(heartScale)
                .animation(.spring(response: 0.35, dampingFraction: 0.72), value: recipe.isFavorited)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - RecipeCardView

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image area
            Group {
                if let data = recipe.thumbnailData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [
                            AppTheme.orange.opacity(0.25),
                            AppTheme.amber.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(AppTheme.orange.opacity(0.6))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .clipped()
            .overlay(alignment: .topLeading) {
                if recipe.needsReview {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.amber)
                        .padding(6)
                        .background(AppTheme.cardWhite.opacity(0.92))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            .overlay(alignment: .topTrailing) {
                FavoriteButton(recipe: recipe)
                    .padding(10)
            }

            // Info area
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let time = recipe.totalTimeMinutes {
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(AppTheme.orange)
                            Text("\(time) min")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !recipe.ingredients.isEmpty {
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("\(recipe.ingredients.count) ingredients")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .background(AppTheme.cardWhite)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 14, y: 4)
    }
}
