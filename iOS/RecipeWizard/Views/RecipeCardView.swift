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

    /// Light warm peach in light mode, deep basil green in dark mode
    static let warmCanvas = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.047, green: 0.118, blue: 0.071, alpha: 1) // deep herb garden
            : UIColor(red: 0.99,  green: 0.96,  blue: 0.89,  alpha: 1) // warm peach
    })

    /// White in light mode, elevated basil card in dark mode
    static let cardWhite = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.082, green: 0.180, blue: 0.110, alpha: 1) // lifted basil
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

struct PressAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

// MARK: - RecipeCardView

struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image area
            ZStack(alignment: .topTrailing) {
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
