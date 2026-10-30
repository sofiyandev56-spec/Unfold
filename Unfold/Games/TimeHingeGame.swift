import SwiftUI

/// Apple history on a protractor. The hinge angle is the dial: fold to pick a year,
/// hold steady to lock it in. Without a hinge, drag the needle.
struct TimeHingeGame: View {
    let onFinish: (GameResult) -> Void
    let onQuit: () -> Void

    static let firstYear = 1976
    static let lastYear = 2026

    @Environment(FoldState.self) private var fold
    @State private var events = Array(Curriculum.timeline.shuffled().prefix(8))
    @State private var round = 0
    @State private var dialYear: Double = 2001
    @State private var guess: Int?
    @State private var armed = false
    @State private var lockProgress: Double = 0
    @State private var score = 0
    @State private var correct = 0
    @State private var misses: [Miss] = []
    @State private var tickYear = 0
    @State private var lockTick = 0
    @State private var finished = false

    private let world = World.ecosystem
    private var event: TimelineEvent { events[min(round, events.count - 1)] }
    private var year: Int { Int(dialYear.rounded()) }
    private var usesHinge: Bool { fold.playableAngle != nil }

    var body: some View {
        VStack(spacing: 0) {
            GameHUD(title: "Time Hinge", score: score, detail: "\(round + 1)/\(events.count)",
                    detailSymbol: "clock.fill", detailColor: world.color, onQuit: onQuit)

            // Once the answer is revealed, the story gets more room than the dial.
            FoldSplit(primaryFraction: guess == nil ? 0.34 : 0.46) {
                eventPanel
            } secondary: {
                dialPanel
            }
            .padding(16)
        }
        .onChange(of: fold.playableAngle) { _, angle in
            guard let angle, guess == nil else { return }
            dialYear = Self.year(forHinge: angle)
            armed = true
        }
        .onChange(of: year) { _, newYear in tickYear = newYear }
        .task(id: year) { await holdToLock() }
        .sensoryFeedback(.selection, trigger: tickYear)
        .sensoryFeedback(.success, trigger: lockTick)
    }

    /// Maps the usable range of the inner display's hinge, 40°–180°, onto fifty years.
    static func year(forHinge angle: Double) -> Double {
        let t = min(max((angle - 40) / 140, 0), 1)
        return Double(firstYear) + t * Double(lastYear - firstYear)
    }

    // MARK: Panels

    private var eventPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("When did this happen?").eyebrow(world.color)
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: event.symbol)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(world.color)
                    .frame(width: 56, height: 56)
                    .background(world.color.opacity(0.15), in: .rect(cornerRadius: 16, style: .continuous))
                Text(event.title)
                    .font(.rounded(.title, weight: .bold))
                    .minimumScaleFactor(0.7)
            }
            if let guess {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(verbatim: "\(event.year)")
                            .font(.rounded(.title2, weight: .heavy))
                            .foregroundStyle(Palette.correct)
                        Text(verdict(for: guess))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Palette.correct.opacity(0.15), in: .capsule)
                    }
                    Text(event.detail).font(.subheadline).foregroundStyle(.secondary)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .surface()
        .animation(.smooth, value: guess)
    }

    private var dialPanel: some View {
        VStack(spacing: 8) {
            Text(verbatim: "\(guess ?? year)")
                .font(.system(size: 60, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(guess ?? year)))
                .animation(.snappy, value: year)
                .foregroundStyle(guess == nil ? .primary : world.color)

            ProtractorDial(year: guess.map(Double.init) ?? dialYear,
                           answer: guess == nil ? nil : event.year,
                           tint: world.color) { newYear in
                guard guess == nil, !usesHinge else { return }
                dialYear = newYear
                armed = true
            }
            .frame(minHeight: 110, maxHeight: 300)
            .layoutPriority(1)

            bottomControls
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .surface()
    }

    @ViewBuilder
    private var bottomControls: some View {
        if guess == nil {
            VStack(spacing: 8) {
                Button { lock() } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().stroke(.white.opacity(0.3), lineWidth: 3)
                            Circle().trim(from: 0, to: lockProgress)
                                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 20, height: 20)
                        Text("Lock in \(String(year))")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(world.color)
                .controlSize(.extraLarge)
                .font(.headline)
                Text(usesHinge ? "Fold to dial the year · hold still to lock" : "Drag the needle, then lock in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Button { nextRound() } label: {
                Label(round + 1 < events.count ? "Next moment" : "See results", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(world.color)
            .controlSize(.extraLarge)
            .font(.headline)
        }
    }

    // MARK: Logic

    private func holdToLock() async {
        guard usesHinge, armed, guess == nil else { return }
        lockProgress = 0
        withAnimation(.linear(duration: 1.3)) { lockProgress = 1 }
        try? await Task.sleep(for: .seconds(1.35))
        guard !Task.isCancelled else { return }
        lock()
    }

    private func lock() {
        guard guess == nil else { return }
        let picked = year
        let diff = abs(picked - event.year)
        let points = switch diff {
        case 0: 100
        case 1: 70
        case 2: 40
        case 3...4: 15
        default: 0
        }
        score += points
        if diff <= 1 {
            correct += 1
        } else {
            misses.append(Miss(game: .timeHinge, prompt: event.title, answer: "\(event.year)", explanation: event.detail))
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { guess = picked }
        lockTick += 1
    }

    private func verdict(for picked: Int) -> String {
        let diff = abs(picked - event.year)
        switch diff {
        case 0: return "Exact!"
        case 1: return "So close: you said \(picked)"
        default: return "You said \(picked), \(diff) years off"
        }
    }

    private func nextRound() {
        guard !finished else { return }
        if round + 1 >= events.count {
            finished = true
            onFinish(GameResult(game: .timeHinge, score: score, correct: correct, total: events.count, misses: misses))
            return
        }
        withAnimation(.smooth) {
            round += 1
            guess = nil
            armed = false
            lockProgress = 0
        }
    }
}

/// A half-circle dial from 1976 on the left to 2026 on the right.
struct ProtractorDial: View {
    let year: Double
    let answer: Int?
    let tint: Color
    let onDrag: (Double) -> Void

    var body: some View {
        GeometryReader { geo in
            let geometry = Self.geometry(in: geo.size)
            ZStack {
                Canvas { context, _ in
                    // End years get labels only when there's room; on a small dial they'd collide with 1980 and 2020.
                    let roomy = geometry.radius > 150
                    for y in TimeHingeGame.firstYear...TimeHingeGame.lastYear {
                        let a = Self.angle(for: Double(y))
                        let isEnd = y == TimeHingeGame.firstYear || y == TimeHingeGame.lastYear
                        let major = y % 10 == 0 || isEnd
                        let length: CGFloat = major ? 16 : (y % 5 == 0 ? 10 : 5)
                        var tick = Path()
                        tick.move(to: Self.point(geometry.center, geometry.radius, a))
                        tick.addLine(to: Self.point(geometry.center, geometry.radius - length, a))
                        context.stroke(tick, with: .color(.white.opacity(major ? 0.7 : 0.25)), lineWidth: major ? 2 : 1)
                        if major, !isEnd || roomy {
                            let label = Text(verbatim: "\(y)").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                            context.draw(label, at: Self.point(geometry.center, geometry.radius - 32, a))
                        }
                    }
                }

                NeedleShape(angle: Self.angle(for: year))
                    .stroke(answer == nil ? tint : .white.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .shadow(color: tint.opacity(0.7), radius: answer == nil ? 8 : 0)
                    .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: year)

                if let answer {
                    NeedleShape(angle: Self.angle(for: Double(answer)))
                        .stroke(Palette.correct, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .shadow(color: Palette.correct.opacity(0.8), radius: 10)
                        .transition(.opacity)
                }

                Circle()
                    .fill(.white)
                    .frame(width: 14, height: 14)
                    .position(geometry.center)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { value in
                    let dx = value.location.x - geometry.center.x
                    let dy = geometry.center.y - value.location.y
                    let a = min(max(atan2(max(dy, 0), dx), 0), .pi)
                    let t = 1 - a / .pi
                    onDrag(Double(TimeHingeGame.firstYear) + t * Double(TimeHingeGame.lastYear - TimeHingeGame.firstYear))
                }
            )
        }
        .accessibilityElement()
        .accessibilityLabel("Year dial")
        .accessibilityValue("\(Int(year.rounded()))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onDrag(min(year.rounded() + 1, Double(TimeHingeGame.lastYear)))
            case .decrement: onDrag(max(year.rounded() - 1, Double(TimeHingeGame.firstYear)))
            @unknown default: break
            }
        }
    }

    static func geometry(in size: CGSize) -> (center: CGPoint, radius: CGFloat) {
        let center = CGPoint(x: size.width / 2, y: size.height - 10)
        let radius = max(min(size.width / 2 - 14, size.height - 24), 40)
        return (center, radius)
    }

    /// Radians: π at 1976 (pointing left) down to 0 at 2026 (pointing right).
    static func angle(for year: Double) -> Double {
        let t = (year - Double(TimeHingeGame.firstYear)) / Double(TimeHingeGame.lastYear - TimeHingeGame.firstYear)
        return .pi * (1 - t)
    }

    static func point(_ center: CGPoint, _ radius: CGFloat, _ angle: Double) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y - sin(angle) * radius)
    }
}

/// The dial's needle, animatable by angle so it sweeps rather than jumps.
struct NeedleShape: Shape {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let geometry = ProtractorDial.geometry(in: rect.size)
        var path = Path()
        path.move(to: geometry.center)
        path.addLine(to: ProtractorDial.point(geometry.center, geometry.radius - 44, angle))
        return path
    }
}
