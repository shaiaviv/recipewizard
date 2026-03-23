import SwiftUI

// MARK: - ShareView

struct ShareView: View {
    let urlString: String?
    let onDismiss: () -> Void

    @State private var stage: ExtractionStage = .idle
    @State private var errorMessage: String?
    @State private var showConfetti = false

    // Local theme constants — AppTheme lives in the main target, not the extension
    private let orange = Color(red: 0.97, green: 0.59, blue: 0.19)
    private let amber  = Color(red: 0.83, green: 0.51, blue: 0.063)
    private let canvas = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.098, green: 0.090, blue: 0.082, alpha: 1) // refined charcoal
            : UIColor(red: 0.99,  green: 0.96,  blue: 0.89,  alpha: 1)
    })

    // MARK: - Stage Model

    enum ExtractionStage: Equatable {
        case idle, fetchingVideo, readingCaption, extractingWithAI, saving, done, failed

        var label: String {
            switch self {
            case .idle:             return "Starting…"
            case .fetchingVideo:    return "Fetching video"
            case .readingCaption:   return "Reading captions"
            case .extractingWithAI: return "Cooking your recipe"
            case .saving:           return "Saving recipe"
            case .done:             return "Recipe saved!"
            case .failed:           return "Couldn't extract the recipe"
            }
        }

        var subtitle: String {
            switch self {
            case .idle:             return "Getting things ready"
            case .fetchingVideo:    return "Pulling the video metadata"
            case .readingCaption:   return "Reading the description"
            case .extractingWithAI: return ""
            case .saving:           return "Adding to your collection"
            case .done:             return "Open RecipeWizard to view it"
            case .failed:           return "Cauldy the Wizard is confused, try another video"
            }
        }

        var iconName: String {
            switch self {
            case .idle:             return "fork.knife"
            case .fetchingVideo:    return "play.rectangle.fill"
            case .readingCaption:   return "text.quote"
            case .extractingWithAI: return "sparkles"
            case .saving:           return "books.vertical.fill"
            case .done:             return "checkmark.circle.fill"
            case .failed:           return "exclamationmark.triangle.fill"
            }
        }

        var progressIndex: Int {
            switch self {
            case .idle:             return 0
            case .fetchingVideo:    return 1
            case .readingCaption:   return 2
            case .extractingWithAI: return 3
            case .saving, .done, .failed: return 4
            }
        }

        var isTerminal: Bool { self == .done || self == .failed }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar.padding(.top, 20)
                Spacer()
                CookingLoaderView(stage: stage, orange: orange, amber: amber, showConfetti: showConfetti)
                Spacer()
            }
        }
        .onChange(of: stage) { _, new in
            if new == .done {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    showConfetti = true
                }
            }
        }
        .task {
            guard let url = urlString else {
                setStage(.failed)
                errorMessage = "No URL found in the shared content."
                return
            }
            await runExtraction(url: url)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(stage == .done ? "Done" : "Cancel") { onDismiss() }
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(Color(.secondaryLabel))

            Spacer()

            Text("RecipeWizard")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Spacer()

            Text(stage == .done ? "Done" : "Cancel")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .hidden()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func setStage(_ s: ExtractionStage) {
        withAnimation(.easeInOut(duration: 0.32)) { stage = s }
    }

    // MARK: - Extraction Pipeline

    private func runExtraction(url: String) async {
        let stages: [ExtractionStage] = [.fetchingVideo, .readingCaption, .extractingWithAI, .saving]

        let extractionTask = Task {
            try await RecipeAPIService.shared.extractRecipe(from: url)
        }

        for s in stages.dropLast() {
            setStage(s)
            try? await Task.sleep(for: .seconds(1))
        }

        do {
            let response = try await extractionTask.value
            setStage(.saving)
            savePendingRecipe(response)
            try? await Task.sleep(for: .milliseconds(700))
            setStage(.done)
            try? await Task.sleep(for: .seconds(1.4))
            onDismiss()
        } catch APIError.unauthorized {
            setStage(.failed)
            errorMessage = "Open RecipeWizard and sign in first, then try again."
        } catch {
            setStage(.failed)
            errorMessage = error.localizedDescription
        }
    }

    private func savePendingRecipe(_ response: RecipeResponse) {
        guard let defaults = UserDefaults(suiteName: SharedConstants.appGroupID) else { return }
        var pending = defaults.array(forKey: SharedConstants.pendingRecipesKey) as? [Data] ?? []
        if let encoded = try? JSONEncoder().encode(response) { pending.append(encoded) }
        defaults.set(pending, forKey: SharedConstants.pendingRecipesKey)
    }
}

// MARK: - CookingLoaderView

/// Full entertainment screen shown during the ~20s AI extraction stage.
/// Cauldy the Wizard dances while ingredients fly in, glitter drifts up,
/// burst sparkles fly outward, and magic rings pulse around him.
private struct CookingLoaderView: View {
    let stage: ShareView.ExtractionStage
    let orange: Color
    let amber: Color
    let showConfetti: Bool

    @State private var messageIndex = 0
    @State private var fakeProgress: CGFloat = 0
    @State private var glowPulse: CGFloat = 0.5

    // All loading messages rotate freely by time — no stage gating.
    // Only saving/terminal messages are stage-specific.
    private static let loadingMessages = [
        "Grabbing your video…",
        "Pulling the metadata…",
        "Reading the captions…",
        "Scanning the description…",
        "Tasting the flavors…",
        "Chopping the ingredients…",
        "Adjusting the seasoning…",
        "Letting it simmer…",
        "Perfecting the recipe…",
        "Almost ready…",
    ]
    private static let savingMessages = ["Saving your recipe…", "Adding to your collection…"]

    private var activeMessages: [String] {
        stage == .saving ? Self.savingMessages : Self.loadingMessages
    }

    private var glowColors: [Color] {
        stage == .done
            ? [Color.green.opacity(0.35 * glowPulse), Color.green.opacity(0.15 * glowPulse), .clear]
            : [orange.opacity(0.38 * glowPulse), amber.opacity(0.20 * glowPulse), .clear]
    }

    // 10 ingredients that fly IN to Cauldy (icon, startX, startY, delay, color)
    private var flyInIngredients: [(String, CGFloat, CGFloat, Double, Color)] {[
        ("leaf.fill",        -100, -20,  0.3,  Color(red: 0.28, green: 0.65, blue: 0.30)),
        ("drop.fill",          98, -45,  1.2,  amber),
        ("flame.fill",        -88,  60,  2.2,  Color(red: 0.95, green: 0.35, blue: 0.15)),
        ("carrot",             92,  55,  3.1,  Color(red: 0.97, green: 0.59, blue: 0.19)),
        ("sparkles",           -6, -98,  4.0,  orange),
        ("fork.knife",        108,  -8,  0.8,  Color(red: 0.60, green: 0.38, blue: 0.20)),
        ("fish.fill",         -92,  22,  1.7,  Color(red: 0.29, green: 0.56, blue: 0.89)),
        ("wand.and.stars",     62,  78,  2.6,  Color(red: 0.67, green: 0.35, blue: 0.92)),
        ("bolt.fill",         -52, -88,  3.8,  Color(red: 0.97, green: 0.80, blue: 0.10)),
        ("star.fill",          80, -72,  4.7,  Color(red: 0.95, green: 0.35, blue: 0.55)),
    ]}

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                // Expanding magic ring pulses
                MagicRingPulse(color: orange, delay: 0.0)
                MagicRingPulse(color: amber,  delay: 1.1)
                MagicRingPulse(color: orange.opacity(0.6), delay: 2.2)

                // Radial glow aura — turns green on done
                Circle()
                    .fill(RadialGradient(
                        colors: glowColors,
                        center: .center, startRadius: 12, endRadius: 85
                    ))
                    .frame(width: 170, height: 170)
                    .scaleEffect(0.82 + 0.18 * glowPulse)
                    .animation(.easeInOut(duration: 0.5), value: stage == .done)

                // 8 glitter particles drifting upward around Cauldy
                ForEach(0..<8, id: \.self) { i in
                    SparkleParticle(index: i, color: i % 2 == 0 ? orange : amber)
                }

                // 6 burst sparkles flying outward from Cauldy
                ForEach(0..<6, id: \.self) { i in
                    BurstParticle(index: i, color: i % 3 == 0 ? orange : (i % 3 == 1 ? amber : Color(red: 0.67, green: 0.35, blue: 0.92)))
                }

                // 10 food ingredients flying in to Cauldy
                ForEach(Array(flyInIngredients.enumerated()), id: \.offset) { _, ing in
                    IngredientParticle(
                        icon: ing.0, startX: ing.1, startY: ing.2,
                        delay: ing.3, color: ing.4
                    )
                }

                // Cauldy dances continuously; swap to sad mascot only on failure
                if stage == .failed {
                    SadMascotView()
                } else {
                    DancingCauldyView(orange: orange, isDone: stage == .done)
                }

                // Confetti erupts on top of the whole scene when done
                if showConfetti {
                    ConfettiBurst(primary: orange, secondary: amber)
                }
            }
            .frame(width: 240, height: 220)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { glowPulse = 1.0 }
            }

            // Terminal stages show the outcome label; active stages rotate messages
            if stage.isTerminal {
                VStack(spacing: 8) {
                    Text(stage.label)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(stage == .done ? Color.green : .primary)
                        .id(stage.label)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 10)),
                            removal:   .opacity.combined(with: .offset(y: -8))
                        ))
                    if !stage.subtitle.isEmpty {
                        Text(stage.subtitle)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 48)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.28), value: stage)
            } else {
                Text(activeMessages[messageIndex % activeMessages.count])
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .id(messageIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 10)),
                        removal:   .opacity.combined(with: .offset(y: -8))
                    ))
                    .animation(.easeInOut(duration: 0.28), value: messageIndex)

                // Single progress bar covering the full ~22s extraction journey.
                // easeOut: rushes through the fast pre-AI steps, then decelerates
                // into the long AI step — mirrors the actual time distribution.
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [orange, amber],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(10, geo.size.width * fakeProgress))
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 32)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.easeInOut(duration: 0.28)) { messageIndex += 1 }
            }
        }
        .onChange(of: stage) { _, new in
            switch new {
            case .fetchingVideo:
                // Reset and restart on every new extraction, including reused extension processes
                fakeProgress = 0
                withAnimation(.linear(duration: 15)) { fakeProgress = 0.88 }
            case .saving:
                withAnimation(.easeInOut(duration: 0.4)) { fakeProgress = 0.95 }
                withAnimation(.easeInOut(duration: 0.28)) { messageIndex = 0 }
            case .done:
                withAnimation(.easeInOut(duration: 0.4)) { fakeProgress = 1.0 }
            default:
                break
            }
        }
    }
}

// MARK: - Ingredient Particle

/// Each particle manages its own looping fly-in animation independently.
private struct IngredientParticle: View {
    let icon: String
    let startX: CGFloat
    let startY: CGFloat
    let delay: Double
    let color: Color

    @State private var x: CGFloat
    @State private var y: CGFloat
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    init(icon: String, startX: CGFloat, startY: CGFloat, delay: Double, color: Color) {
        self.icon = icon; self.startX = startX; self.startY = startY
        self.delay = delay; self.color = color
        _x = State(initialValue: startX)
        _y = State(initialValue: startY)
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(color)
            .offset(x: x, y: y)
            .scaleEffect(scale)
            .opacity(opacity)
            .task {
                try? await Task.sleep(for: .seconds(delay))
                await loop()
            }
    }

    private func loop() async {
        while !Task.isCancelled {
            // 1. Reset to start (instant — no withAnimation)
            x = startX; y = startY; scale = 0; opacity = 0

            // Allow one frame to commit the reset before animating
            try? await Task.sleep(for: .milliseconds(32))

            // 2. Pop into view at start position
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                scale = 1.0; opacity = 1.0
            }
            try? await Task.sleep(for: .seconds(0.38))

            // 3. Fly into Cauldy (easeIn: accelerates as it approaches center)
            withAnimation(.easeIn(duration: 0.95)) {
                x = 0; y = 18   // slightly below center = absorbed by Cauldy
                scale = 0.15
                opacity = 0
            }
            try? await Task.sleep(for: .seconds(1.05))

            // 4. Wait a random interval before the next appearance
            let pause = Double.random(in: 2.2...4.8)
            try? await Task.sleep(for: .seconds(pause))
        }
    }
}

// MARK: - Dancing Cauldy View

/// Cauldy doing one continuous fun dance — three axes at different cadences
/// produce natural beat-interference motion. No stage resets; the animation
/// runs uninterrupted for the entire loading experience.
private struct DancingCauldyView: View {
    let orange: Color
    let isDone: Bool

    @State private var bob:  CGFloat = 0
    @State private var sway: CGFloat = 0
    @State private var rock: Double  = 0

    var body: some View {
        Image("MascotIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 122, height: 122)
            .offset(x: sway, y: bob)
            .rotationEffect(.degrees(rock))
            .shadow(color: isDone ? Color.green.opacity(0.40) : orange.opacity(0.30), radius: 16, x: 0, y: 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { bob  = -13 }
                withAnimation(.easeInOut(duration: 2.3).repeatForever(autoreverses: true)) { sway = 9 }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { rock = 7 }
            }
    }
}

// MARK: - Sad Mascot View

/// MascotSad with a slow mournful float — shown only on the failed state.
private struct SadMascotView: View {
    @State private var bob:  CGFloat = 0
    @State private var rock: Double  = 0

    var body: some View {
        Image("MascotSad")
            .resizable()
            .scaledToFit()
            .frame(width: 122, height: 122)
            .offset(y: bob)
            .rotationEffect(.degrees(rock))
            .onAppear {
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { bob  = -12 }
                withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) { rock = 4 }
            }
    }
}

// MARK: - Magic Ring Pulse

/// An expanding circle stroke that fades out — three staggered instances create
/// a ripple effect around Cauldy.
private struct MagicRingPulse: View {
    let color: Color
    let delay: Double

    @State private var scale: CGFloat = 0.35
    @State private var opacity: Double = 0.0

    var body: some View {
        Circle()
            .strokeBorder(color.opacity(opacity), lineWidth: 1.5)
            .frame(width: 158, height: 158)
            .scaleEffect(scale)
            .task { await loop() }
    }

    private func loop() async {
        try? await Task.sleep(for: .seconds(delay))
        while !Task.isCancelled {
            scale = 0.35; opacity = 0.7
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.easeOut(duration: 1.7)) { scale = 1.75; opacity = 0 }
            try? await Task.sleep(for: .seconds(2.3))
        }
    }
}

// MARK: - Sparkle Particle (glitter drifting upward)

/// Small sparkle glyphs that appear at fixed orbital positions around Cauldy,
/// drift upward with a slight lateral wobble, then fade — like rising glitter.
private struct SparkleParticle: View {
    let index: Int
    let color: Color

    @State private var yOffset: CGFloat = 0
    @State private var xDrift: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0

    // Distributed evenly around Cauldy at varying radii
    private var spawnX: CGFloat {
        let xs: [CGFloat] = [-78, -48, -15, 22, 52, 80, 95, -95]
        return xs[index % xs.count]
    }
    private var spawnY: CGFloat {
        let ys: [CGFloat] = [30, -38, 55, -52, 28, -15, 55, 10]
        return ys[index % ys.count]
    }
    private var glyphSize: CGFloat { CGFloat(6 + (index * 3) % 9) }

    var body: some View {
        Image(systemName: index % 2 == 0 ? "sparkle" : "star.fill")
            .font(.system(size: glyphSize, weight: .ultraLight))
            .foregroundStyle(color)
            .offset(x: spawnX + xDrift, y: spawnY + yOffset)
            .scaleEffect(scale)
            .opacity(opacity)
            .task { await loop() }
    }

    private func loop() async {
        try? await Task.sleep(for: .seconds(Double(index) * 0.42))
        while !Task.isCancelled {
            yOffset = 0; xDrift = 0; scale = 0; opacity = 0
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.spring(response: 0.32, dampingFraction: 0.65)) { scale = 1.0; opacity = 0.88 }
            withAnimation(.easeInOut(duration: 1.9)) {
                yOffset = -42
                xDrift  = CGFloat.random(in: -18...18)
            }
            try? await Task.sleep(for: .seconds(1.15))
            withAnimation(.easeIn(duration: 0.65)) { opacity = 0; scale = 0.2 }
            try? await Task.sleep(for: .seconds(0.75))
            try? await Task.sleep(for: .seconds(Double.random(in: 0.7...2.2)))
        }
    }
}

// MARK: - Burst Particle (sparkles flying outward from Cauldy)

/// Sparkles that erupt outward from Cauldy's center like a magical shockwave,
/// giving the impression he's conjuring energy.
private struct BurstParticle: View {
    let index: Int
    let color: Color

    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    private var angle: Double { Double(index) * 60.0 + Double(index * 19) }
    private var distance: CGFloat { CGFloat(58 + (index * 14) % 38) }
    private var targetX: CGFloat { CGFloat(cos(angle * .pi / 180)) * distance }
    private var targetY: CGFloat { CGFloat(sin(angle * .pi / 180)) * distance }
    private var glyphSize: CGFloat { CGFloat(8 + (index * 4) % 7) }

    var body: some View {
        Image(systemName: index % 2 == 0 ? "sparkle" : "star.fill")
            .font(.system(size: glyphSize, weight: .thin))
            .foregroundStyle(color)
            .offset(x: x, y: y)
            .scaleEffect(scale)
            .opacity(opacity)
            .task { await loop() }
    }

    private func loop() async {
        try? await Task.sleep(for: .seconds(Double(index) * 0.38))
        while !Task.isCancelled {
            x = 0; y = 0; scale = 0; opacity = 0
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.spring(response: 0.28, dampingFraction: 0.62)) { scale = 1.3; opacity = 1.0 }
            withAnimation(.easeOut(duration: 0.65)) { x = targetX; y = targetY }
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.easeIn(duration: 0.55)) { opacity = 0; scale = 0.1 }
            try? await Task.sleep(for: .seconds(0.6))
            try? await Task.sleep(for: .seconds(Double.random(in: 1.2...3.0)))
        }
    }
}

// MARK: - Confetti Burst

private struct ConfettiBurst: View {
    let primary: Color
    let secondary: Color

    @State private var animate = false

    private let particles: [(Double, CGFloat, CGFloat)] = [
        (10, 72, 9), (50, 84, 7), (90, 68, 10), (130, 80, 7),
        (170, 74, 8), (210, 86, 6), (250, 70, 9), (290, 78, 7),
        (330, 66, 8), (380, 75, 6),
    ]

    var body: some View {
        ZStack {
            ForEach(Array(particles.enumerated()), id: \.offset) { i, p in
                let (angle, dist, size) = p
                Circle()
                    .fill(i.isMultiple(of: 2) ? primary : secondary)
                    .frame(width: size, height: size)
                    .offset(
                        x: animate ? cos(angle * .pi / 180) * dist : 0,
                        y: animate ? sin(angle * .pi / 180) * dist : 0
                    )
                    .scaleEffect(animate ? 0.2 : 1.0)
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.75)) { animate = true }
        }
    }
}
