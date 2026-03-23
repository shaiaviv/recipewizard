import SwiftUI

// MARK: - ShareView

struct ShareView: View {
    let urlString: String?
    let onDismiss: () -> Void

    @State private var stage: ExtractionStage = .idle
    @State private var errorMessage: String?
    @State private var showConfetti = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var sadFloat: CGFloat = 0
    @State private var sadRotation: Double = 0

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
            case .failed:           return "Cauldy the wizard is confused, try another video"
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

                if stage == .extractingWithAI {
                    CookingLoaderView(orange: orange, amber: amber)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    iconArea
                    Spacer().frame(height: 32)
                    labelArea
                }

                Spacer()

                if stage != .extractingWithAI {
                    bottomArea.padding(.bottom, 52)
                }
            }
            .animation(.easeInOut(duration: 0.38), value: stage == .extractingWithAI)
        }
        .onChange(of: stage) { _, new in
            if new == .done {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                    showConfetti = true
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                pulseScale = 1.18
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

    // MARK: - Icon Area (non-cooking stages)

    private var iconArea: some View {
        Group {
            if stage == .failed {
                sadMascotArea
            } else {
                normalIconArea
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: stage)
    }

    private var sadMascotArea: some View {
        Image("MascotSad")
            .resizable()
            .scaledToFit()
            .frame(width: 180, height: 180)
            .offset(y: sadFloat)
            .rotationEffect(.degrees(sadRotation))
            .id("sad")
            .onAppear {
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    sadFloat = -12
                }
                withAnimation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true)) {
                    sadRotation = 4
                }
            }
    }

    private var normalIconArea: some View {
        ZStack {
            if !stage.isTerminal {
                Circle()
                    .fill(orange.opacity(0.07))
                    .frame(width: 190, height: 190)
                    .scaleEffect(pulseScale)
            }
            Circle()
                .fill(glowColor.opacity(0.11))
                .frame(width: 148, height: 148)
            Circle()
                .fill(glowColor.opacity(0.16))
                .frame(width: 108, height: 108)

            Image(systemName: stage.iconName)
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(glowColor)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: stage)

            if showConfetti {
                ConfettiBurst(primary: orange, secondary: amber)
            }
        }
        .frame(width: 190, height: 190)
    }

    // MARK: - Label Area (non-cooking stages)

    private var labelArea: some View {
        VStack(spacing: 10) {
            Text(stage.label)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .id(stage.label)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 12)),
                    removal:   .opacity.combined(with: .offset(y: -8))
                ))

            if !stage.subtitle.isEmpty {
                Text(stage.subtitle)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .id(stage.subtitle)
                    .transition(.opacity)
            }

            if stage == .failed, let err = errorMessage {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: stage)
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        Group {
            if !stage.isTerminal {
                HStack(spacing: 7) {
                    ForEach(1...4, id: \.self) { i in
                        Capsule()
                            .fill(i <= stage.progressIndex ? orange : Color(.tertiarySystemFill))
                            .frame(height: 4)
                            .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.06), value: stage.progressIndex)
                    }
                }
                .padding(.horizontal, 48)
            }
        }
    }

    // MARK: - Helpers

    private var glowColor: Color {
        stage == .done ? .green : orange
    }

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
/// Features a drawn pot, ingredients flying in, steam wisps, rotating messages,
/// and a fake progress bar that fills with easeOut timing.
private struct CookingLoaderView: View {
    let orange: Color
    let amber: Color

    @State private var messageIndex = 0
    @State private var fakeProgress: CGFloat = 0

    private let messages = [
        "Tasting the flavors…",
        "Chopping the ingredients…",
        "Adjusting the seasoning…",
        "Letting it simmer…",
        "Perfecting the recipe…",
        "Almost ready…",
    ]

    // (icon, startX, startY, initialDelay, color)
    private var ingredients: [(String, CGFloat, CGFloat, Double, Color)] {[
        ("leaf.fill",  -95, -15, 0.3,  Color(red: 0.28, green: 0.65, blue: 0.30)),
        ("drop.fill",   90, -40, 1.2,  amber),
        ("flame.fill", -80,  55, 2.2,  Color(red: 0.95, green: 0.35, blue: 0.15)),
        ("carrot",      88,  50, 3.1,  Color(red: 0.97, green: 0.59, blue: 0.19)),
        ("sparkles",    -5, -90, 4.0,  orange),
    ]}

    var body: some View {
        VStack(spacing: 22) {
            // Scene
            ZStack {
                ForEach(Array(ingredients.enumerated()), id: \.offset) { _, ing in
                    IngredientParticle(
                        icon: ing.0, startX: ing.1, startY: ing.2,
                        delay: ing.3, color: ing.4
                    )
                }
                SteamWisps()
                    .offset(y: -60)
                PotView(orange: orange, amber: amber)
            }
            .frame(width: 220, height: 200)

            // Rotating message
            Text(messages[messageIndex % messages.count])
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

            // Fake progress bar — easeOut so it feels snappy then tapers
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
        .task {
            // Fake progress: 0 → 0.88, easeOut so it starts fast then decelerates
            withAnimation(.easeOut(duration: 19)) {
                fakeProgress = 0.88
            }
            // Rotate messages every 3.5s
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.easeInOut(duration: 0.28)) {
                    messageIndex += 1
                }
            }
        }
    }
}

// MARK: - Pot

private struct PotView: View {
    let orange: Color
    let amber: Color

    var body: some View {
        ZStack {
            // Ground shadow
            Ellipse()
                .fill(Color.black.opacity(0.07))
                .frame(width: 84, height: 12)
                .blur(radius: 4)
                .offset(y: 46)

            // Pot body
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(LinearGradient(
                    colors: [orange, amber],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 78, height: 62)
                .offset(y: 10)

            // Interior darkness (open top)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .frame(width: 60, height: 16)
                .offset(y: -14)

            // Rim
            Capsule()
                .fill(amber)
                .frame(width: 90, height: 13)
                .offset(y: -20)

            // Left handle
            Capsule()
                .fill(amber)
                .frame(width: 24, height: 10)
                .rotationEffect(.degrees(-20))
                .offset(x: -53, y: -16)

            // Right handle
            Capsule()
                .fill(amber)
                .frame(width: 24, height: 10)
                .rotationEffect(.degrees(20))
                .offset(x: 53, y: -16)
        }
    }
}

// MARK: - Steam Wisps

private struct SteamWisps: View {
    @State private var phase = false

    var body: some View {
        HStack(spacing: 11) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Color(.secondaryLabel).opacity(0.22))
                    .frame(width: 4, height: 20)
                    .rotationEffect(.degrees(Double(i - 1) * 11))
                    .offset(y: phase ? -(CGFloat(i) * 3 + 8) : 0)
                    .opacity(phase ? 0.55 - Double(i) * 0.1 : 0)
                    .animation(
                        .easeInOut(duration: 1.15 + Double(i) * 0.18)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.28),
                        value: phase
                    )
            }
        }
        .onAppear { phase = true }
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

            // 3. Fly into the pot (easeIn: accelerates as it approaches center)
            withAnimation(.easeIn(duration: 0.95)) {
                x = 0; y = 18   // slightly below center = inside the pot
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
