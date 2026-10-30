import SwiftUI

/// Sixty seconds of "what prints?" and "will it compile?".
///
/// Code and answers live in a `FoldSplit`: stacked on the cover display, and split across
/// the crease in laptop pose, with the code on the raised half and the answers on the half
/// resting on the table.
struct SprintGame: View {
    let onFinish: (GameResult) -> Void
    let onQuit: () -> Void

    @State private var deck = Curriculum.sprint.shuffled()
    @State private var index = 0
    @State private var score = 0
    @State private var streak = 0
    @State private var correct = 0
    @State private var answered = 0
    @State private var misses: [Miss] = []
    @State private var remaining: Double = 60
    @State private var picked: Int?
    @State private var finished = false
    @State private var goodTick = 0
    @State private var badTick = 0

    private let duration: Double = 60
    private let world = World.swift
    private var question: SprintQuestion { deck[index % deck.count] }

    var body: some View {
        VStack(spacing: 0) {
            GameHUD(title: "Swift Sprint", score: score,
                    detail: String(format: "0:%02d", Int(remaining.rounded(.up))),
                    detailColor: world.color, timeLeft: remaining / duration, onQuit: onQuit)

            FoldSplit(primaryFraction: 0.5) {
                codePanel
            } secondary: {
                answerPanel
            }
            .padding(16)
        }
        .task { await runClock() }
        .sensoryFeedback(.success, trigger: goodTick)
        .sensoryFeedback(.error, trigger: badTick)
    }

    private var codePanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(question.concept).eyebrow(world.color)
                    Spacer()
                    if streak > 1 {
                        Label("×\(min(streak, 5))", systemImage: "flame.fill")
                            .font(.rounded(.subheadline, weight: .heavy))
                            .foregroundStyle(Palette.streak)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text(question.prompt).font(.rounded(.title2))
                CodeView(code: question.code, size: 15)
            }
            .padding(20)
            .id(index)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .scrollBounceBehavior(.basedOnSize)
        .surface()
        .animation(.bouncy, value: streak)
    }

    private var answerPanel: some View {
        VStack(spacing: 12) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { offset, option in
                        AnswerButton(text: option, code: question.codeOptions, state: state(for: offset)) {
                            choose(offset)
                        }
                    }
                }
                .id(index)
                .transition(.opacity)
            }
            .scrollBounceBehavior(.basedOnSize)

            if let picked, picked != question.answer {
                Label(question.explanation, systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .surface(radius: 18, stroke: Palette.streak.opacity(0.35))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: picked)
    }

    private func state(for option: Int) -> AnswerButton.Status {
        guard let picked else { return .idle }
        if option == question.answer { return .correct }
        if option == picked { return .wrong }
        return .dimmed
    }

    private func choose(_ option: Int) {
        guard picked == nil, !finished else { return }
        picked = option
        answered += 1
        let right = option == question.answer
        if right {
            correct += 1
            streak += 1
            score += 100 * min(streak, 5)
            goodTick += 1
        } else {
            streak = 0
            badTick += 1
            misses.append(Miss(game: .sprint, prompt: question.code,
                               answer: question.options[question.answer], explanation: question.explanation))
        }
        Task {
            try? await Task.sleep(for: .seconds(right ? 0.65 : 2.2))
            guard !finished else { return }
            withAnimation(.smooth(duration: 0.35)) {
                picked = nil
                index += 1
            }
        }
    }

    private func runClock() async {
        while remaining > 0 {
            try? await Task.sleep(for: .milliseconds(100))
            if Task.isCancelled { return }
            remaining = max(remaining - 0.1, 0)
        }
        finish()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish(GameResult(game: .sprint, score: score, correct: correct, total: max(answered, 1), misses: misses))
    }
}

struct AnswerButton: View {
    enum Status { case idle, correct, wrong, dimmed }

    let text: String
    let code: Bool
    let status: Status
    let action: () -> Void

    init(text: String, code: Bool, state: Status, action: @escaping () -> Void) {
        self.text = text
        self.code = code
        self.status = state
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(text)
                    .font(code ? .system(.body, design: .monospaced).weight(.medium) : .body.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let symbol {
                    Image(systemName: symbol)
                        .font(.title3.weight(.bold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .frame(minHeight: 62)
            .background(fill, in: .rect(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(stroke, lineWidth: status == .idle ? 1 : 2)
            }
            .opacity(status == .dimmed ? 0.4 : 1)
            .modifier(Shake(amount: status == .wrong ? 1 : 0))
        }
        .buttonStyle(PressableStyle())
        .animation(.smooth(duration: 0.3), value: status)
        .accessibilityValue(status == .correct ? "Correct answer" : status == .wrong ? "Wrong" : "")
    }

    private var symbol: String? {
        switch status {
        case .correct: "checkmark.circle.fill"
        case .wrong: "xmark.circle.fill"
        default: nil
        }
    }

    private var fill: Color {
        switch status {
        case .correct: Palette.correct.opacity(0.22)
        case .wrong: Palette.incorrect.opacity(0.2)
        default: Palette.raised
        }
    }

    private var stroke: Color {
        switch status {
        case .correct: Palette.correct
        case .wrong: Palette.incorrect
        default: Palette.hairline
        }
    }
}

/// A short horizontal shake for wrong answers.
struct Shake: GeometryEffect {
    var amount: CGFloat

    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(amount * .pi * 4), y: 0))
    }
}
