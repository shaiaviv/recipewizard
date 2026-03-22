import SwiftUI

struct LoadingView: View {
    let stage: String
    @State private var animating = false

    var body: some View {
        HStack(spacing: 14) {
            // Animated terracotta dots
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(AppTheme.terracotta)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animating ? 1.0 : 0.45)
                        .opacity(animating ? 1.0 : 0.35)
                        .animation(
                            .easeInOut(duration: 0.48)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                            value: animating
                        )
                }
            }

            Text(stage.isEmpty ? "Processing…" : stage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear { animating = true }
    }
}
