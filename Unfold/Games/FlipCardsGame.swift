import SwiftUI

/// Flashcards whose flip is driven by the hinge.
///
/// The card turns on the same axis as the device: around X when the crease is horizontal
/// (laptop), around Y when it is vertical (book). Folding past 90° reveals the answer;
/// unfolding flat deals the next card. Without a hinge, drag or tap to flip.
struct FlipCardsGame: View {
    let onFinish: (GameResult) -> Void
    let onQuit: () -> Void

    @Environment(FoldState.self) private var fold
    @Environment(\.windowSize) private var window
    @Environment(ProgressStore.self) private var progress
    @State private var deck: [FlipCard] = []
    @State private var index = 0
    @State private var manualFlip: Double = 0
    @State private var dragStart: Double?
    @State private var revealed = false
    @State private var awaitingUnfold = false
    @State private var knew = 0
    @State private var misses: [Miss] = []
    @State private var revealTick = 0
    @State private var dealTick = 0
    @State private var finished = false

    private let world = World.frameworks
    private var usesHinge: Bool { fold.playableAngle != nil }
    private var card: FlipCard? { index < deck.count ? deck[index] : nil }

    /// 0 shows the task, 1 shows the answer.
    private var flip: Double {
        if awaitingUnfold { return 1 }
        return usesHinge ? fold.foldAmount : manualFlip
    }

    var body: some View {
        VStack(spacing: 0) {
            GameHUD(title: "Fold & Flip", score: knew * 100,
                    detail: "\(min(index + 1, max(deck.count, 1)))/\(max(deck.count, 1))",
                    detailSymbol: "rectangle.stack.fill", detailColor: world.color, onQuit: onQuit)

            FoldSplit(primaryFraction: 0.8) {
                GeometryReader { _ in
                    // Turn on the hinge's own axis: horizontal in laptop pose, vertical in book pose.
                    // A hand-dragged card turns like a page.
                    let axis: (x: CGFloat, y: CGFloat, z: CGFloat) = usesHinge && !window.isLandscape ? (1, 0, 0) : (0, 1, 0)
                    if let card {
                        cardView(card, axis: axis)
                            .frame(maxWidth: 440, maxHeight: 560)
                            .aspectRatio(0.72, contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .id(card.id)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.85)).combined(with: .opacity),
                                                    removal: .move(edge: .top).combined(with: .opacity)))
                    }
                }
            } secondary: {
                controls
            }
            .padding(16)
        }
        .onAppear {
            if deck.isEmpty { deck = progress.studyDeck(count: 10) }
        }
        .onChange(of: fold.foldAmount) { _, amount in
            guard usesHinge else { return }
            if awaitingUnfold, amount < 0.1 {
                deal()
            } else if !revealed, amount > 0.55 {
                revealed = true
                revealTick += 1
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: revealTick)
        .sensoryFeedback(.selection, trigger: dealTick)
    }

    // MARK: Card

    private func cardView(_ card: FlipCard, axis: (x: CGFloat, y: CGFloat, z: CGFloat)) -> some View {
        ZStack {
            front(card)
                .opacity(flip < 0.5 ? 1 : 0)
            back(card)
                .rotation3DEffect(.degrees(180), axis: axis)
                .opacity(flip >= 0.5 ? 1 : 0)
        }
        // Shade the card as it turns edge-on, the way a real card catches less light.
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.black.opacity(sin(flip * .pi) * 0.45))
                .allowsHitTesting(false)
        }
        .rotation3DEffect(.degrees(flip * 180), axis: axis, perspective: 0.55)
        .shadow(color: world.color.opacity(0.25 + 0.2 * sin(flip * .pi)), radius: 30, y: 16)
        .animation(usesHinge ? .interactiveSpring(response: 0.25, dampingFraction: 0.86) : nil, value: flip)
        .contentShape(.rect(cornerRadius: 32))
        .onTapGesture { if !usesHinge { toggleFlip() } }
        .gesture(usesHinge ? nil : flipDrag)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(flip < 0.5 ? "Task: \(card.task)" : "Answer: \(card.answer). \(card.detail)")
        .accessibilityAction(named: "Flip card") { toggleFlip() }
    }

    private func front(_ card: FlipCard) -> some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [world.color, Color(.displayP3, red: 0.10, green: 0.30, blue: 0.75)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: card.symbol)
                .font(.system(size: 180, weight: .bold))
                .foregroundStyle(.white.opacity(0.12))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 30, y: 30)
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: card.symbol)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("Which framework or API?").eyebrow(.white.opacity(0.75))
                Text(card.task)
                    .font(.rounded(.title, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                Spacer()
                HStack(spacing: 10) {
                    HingeGlyph(angle: 120)
                        .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 26, height: 16)
                    Text(usesHinge ? "Fold to flip" : "Tap or drag to flip")
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(26)
        }
        .clipShape(.rect(cornerRadius: 32, style: .continuous))
    }

    private func back(_ card: FlipCard) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Answer").eyebrow(world.color)
            Text(card.answer)
                .font(.rounded(.largeTitle, weight: .heavy))
                .minimumScaleFactor(0.5)
                .lineLimit(2)
            Text(card.detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            CodeView(code: card.snippet, size: 12)
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Palette.raisedHigh, in: .rect(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(world.color.opacity(0.6), lineWidth: 1.5)
        }
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        VStack {
            Spacer(minLength: 0)
            if revealed && !awaitingUnfold {
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button { grade(knewIt: false) } label: {
                            Label("Still learning", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        Button { grade(knewIt: true) } label: {
                            Label("Knew it", systemImage: "checkmark").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Palette.correct)
                    }
                    .controlSize(.extraLarge)
                    .font(.headline)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if awaitingUnfold {
                HStack(spacing: 12) {
                    PhaseAnimator([95.0, 175.0]) { angle in
                        HingeGlyph(angle: angle)
                            .stroke(world.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .frame(width: 36, height: 22)
                    } animation: { _ in .easeInOut(duration: 1.0) }
                    Text("Unfold to deal the next card").font(.headline)
                }
                .transition(.opacity)
            } else {
                Text(usesHinge ? "Recall the answer, then fold to check." : "Recall the answer, then flip to check.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: revealed)
        .animation(.smooth, value: awaitingUnfold)
    }

    // MARK: Actions

    private var flipDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if dragStart == nil { dragStart = manualFlip }
                let start = dragStart ?? 0
                manualFlip = min(max(start - value.translation.width / 260, 0), 1)
            }
            .onEnded { _ in
                dragStart = nil
                settle(to: manualFlip > 0.5 ? 1 : 0)
            }
    }

    private func toggleFlip() {
        settle(to: manualFlip > 0.5 ? 0 : 1)
    }

    private func settle(to target: Double) {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) { manualFlip = target }
        if target == 1, !revealed {
            revealed = true
            revealTick += 1
        }
    }

    private func grade(knewIt: Bool) {
        guard let card else { return }
        progress.grade(cardID: card.id, knewIt: knewIt)
        if knewIt {
            knew += 1
        } else {
            misses.append(Miss(game: .flipCards, prompt: card.task, answer: card.answer, explanation: card.detail))
        }
        if usesHinge, fold.foldAmount > 0.1, index + 1 < deck.count {
            awaitingUnfold = true
        } else {
            deal()
        }
    }

    private func deal() {
        guard !finished else { return }
        if index + 1 >= deck.count {
            finished = true
            onFinish(GameResult(game: .flipCards, score: knew * 100, correct: knew, total: deck.count, misses: misses))
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            index += 1
            manualFlip = 0
            revealed = false
            awaitingUnfold = false
        }
        dealTick += 1
    }
}
