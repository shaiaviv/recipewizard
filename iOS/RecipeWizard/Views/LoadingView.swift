import SwiftUI

struct LoadingView: View {
    let stage: String

    @State private var pulseScale: CGFloat = 1.0
    @State private var iconName: String = "fork.knife"

    // Map stage strings to matching SF Symbols
    private static let stageIcons: [(substring: String, icon: String)] = [
        ("fetch",   "play.rectangle.fill"),
        ("caption", "text.quote"),
        ("ai",      "sparkles"),
        ("saving",  "books.vertical.fill"),
        ("saved",   "checkmark.circle.fill"),
    ]

    private var resolvedIcon: String {
        let lower = stage.lowercased()
        return Self.stageIcons.first { lower.contains($0.substring) }?.icon ?? "fork.knife"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Icon with breathing glow
            ZStack {
                Circle()
                    .fill(AppTheme.orange.opacity(0.08))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale)

                Circle()
                    .fill(AppTheme.orange.opacity(0.13))
                    .frame(width: 68, height: 68)

                Image(systemName: resolvedIcon)
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(AppTheme.orange)
                    .contentTransition(.symbolEffect(.replace))
                    .id(resolvedIcon)
            }
            .frame(width: 90, height: 90)

            // Stage text
            Text(stage.isEmpty ? "Processing…" : stage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .id(stage)
                .transition(.opacity.combined(with: .offset(y: 6)))
                .animation(.easeInOut(duration: 0.25), value: stage)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.16
            }
        }
    }
}
