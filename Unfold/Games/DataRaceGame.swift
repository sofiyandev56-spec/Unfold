import SwiftUI

/// Swift concurrency, made physical: the fold is the isolation boundary.
///
/// Values appear on the `@MainActor` side. Drag Sendable ones across the boundary to
/// `actor Store`; keep the rest home. On iPhone Duo the boundary sits exactly on the crease.
struct DataRaceGame: View {
    let onFinish: (GameResult) -> Void
    let onQuit: () -> Void

    private enum Outcome: Equatable {
        case safeSend, safeKeep, race, tooCautious

        var isMistake: Bool { self == .race || self == .tooCautious }
    }

    @Environment(FoldState.self) private var fold
    @Environment(\.windowSize) private var window
    @State private var tiles = Array(Curriculum.raceTiles.shuffled().prefix(12))
    @State private var index = 0
    @State private var score = 0
    @State private var lives = 3
    @State private var correct = 0
    @State private var misses: [Miss] = []
    @State private var drag: CGSize = .zero
    @State private var outcome: Outcome?
    @State private var goodTick = 0
    @State private var badTick = 0
    @State private var finished = false

    private let home = Palette.tint
    private let away = World.ecosystem.color

    private var tile: RaceTile? { index < tiles.count ? tiles[index] : nil }

    var body: some View {
        VStack(spacing: 0) {
            GameHUD(title: "Data Race", score: score, detail: "\(lives)", detailSymbol: "heart.fill",
                    detailColor: Palette.incorrect, onQuit: onQuit)

            GeometryReader { geo in
                let crease = geo.crease(for: fold, window: window)
                let sideBySide = crease.map(\.isVertical) ?? (geo.size.width > geo.size.height * 1.1)
                let wall = wallRect(in: geo.size, crease: crease, sideBySide: sideBySide)
                let (homeRect, awayRect) = domainRects(in: geo.size, wall: wall, sideBySide: sideBySide)

                ZStack {
                    DomainPanel(title: "@MainActor", subtitle: "UI isolation domain", symbol: "iphone", color: home)
                        .frame(width: homeRect.width, height: homeRect.height)
                        .position(x: homeRect.midX, y: homeRect.midY)
                    DomainPanel(title: "actor Store", subtitle: "Its own isolation domain", symbol: "externaldrive.fill", color: away)
                        .frame(width: awayRect.width, height: awayRect.height)
                        .position(x: awayRect.midX, y: awayRect.midY)

                    BoundaryWall(vertical: sideBySide, flash: outcome)
                        .frame(width: wall.width, height: wall.height)
                        .position(x: wall.midX, y: wall.midY)

                    if let tile {
                        TileCard(tile: tile, outcome: outcome)
                            .frame(width: min(min(homeRect.width, awayRect.width) - 28, 330))
                            .offset(outcome == nil ? drag : .zero)
                            .gesture(dragGesture(home: homeRect, wall: wall, sideBySide: sideBySide))
                            .position(tilePosition(home: homeRect, away: awayRect, wall: wall))
                            .id(tile.id)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: outcome)
                .animation(.smooth(duration: 0.45), value: crease)
            }
            .padding(16)

            controls
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .sensoryFeedback(.success, trigger: goodTick)
        .sensoryFeedback(.error, trigger: badTick)
    }

    // MARK: Layout

    private func wallRect(in size: CGSize, crease: Crease?, sideBySide: Bool) -> CGRect {
        if let crease {
            let thickness: CGFloat = max(crease.isVertical ? crease.frame.width : crease.frame.height, 20)
            return crease.isVertical
                ? CGRect(x: crease.frame.midX - thickness / 2, y: 0, width: thickness, height: size.height)
                : CGRect(x: 0, y: crease.frame.midY - thickness / 2, width: size.width, height: thickness)
        }
        let thickness: CGFloat = 24
        return sideBySide
            ? CGRect(x: size.width / 2 - thickness / 2, y: 0, width: thickness, height: size.height)
            : CGRect(x: 0, y: size.height / 2 - thickness / 2, width: size.width, height: thickness)
    }

    private func domainRects(in size: CGSize, wall: CGRect, sideBySide: Bool) -> (CGRect, CGRect) {
        let gap: CGFloat = 6
        if sideBySide {
            return (CGRect(x: 0, y: 0, width: wall.minX - gap, height: size.height),
                    CGRect(x: wall.maxX + gap, y: 0, width: size.width - wall.maxX - gap, height: size.height))
        }
        return (CGRect(x: 0, y: 0, width: size.width, height: wall.minY - gap),
                CGRect(x: 0, y: wall.maxY + gap, width: size.width, height: size.height - wall.maxY - gap))
    }

    /// Domain titles take the top of each panel; tiles sit centred in the space below.
    private static let headerHeight: CGFloat = 60

    private func tilePosition(home: CGRect, away: CGRect, wall: CGRect) -> CGPoint {
        switch outcome {
        case .safeSend: CGPoint(x: away.midX, y: away.midY + Self.headerHeight / 2)
        // A data race never makes it across: the value sticks in the wall.
        case .race: wall.height > wall.width
            ? CGPoint(x: wall.midX, y: home.midY + Self.headerHeight / 2)
            : CGPoint(x: home.midX, y: wall.midY)
        default: CGPoint(x: home.midX, y: home.midY + Self.headerHeight / 2)
        }
    }

    private func dragGesture(home: CGRect, wall: CGRect, sideBySide: Bool) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard outcome == nil else { return }
                drag = value.translation
            }
            .onEnded { value in
                guard outcome == nil else { return }
                let crossed = sideBySide
                    ? home.midX + value.translation.width > wall.midX
                    : home.midY + Self.headerHeight / 2 + value.translation.height > wall.midY
                if crossed {
                    send()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = .zero }
                }
            }
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        if let outcome, let tile {
            FeedbackCard(tile: tile, outcome: outcome) { next() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button { keep() } label: {
                        Label("Keep isolated", systemImage: "lock.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    Button { send() } label: {
                        Label("Send across", systemImage: "arrow.right.circle.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(away)
                }
                .controlSize(.extraLarge)
                .font(.headline)
            }
            .transition(.opacity)
        }
    }

    // MARK: Rules

    private func send() {
        guard let tile, outcome == nil else { return }
        drag = .zero
        if tile.isSendable {
            score += 100
            correct += 1
            outcome = .safeSend
            goodTick += 1
            autoAdvance()
        } else {
            lives -= 1
            outcome = .race
            badTick += 1
            misses.append(Miss(game: .dataRace, prompt: tile.code, answer: "Not Sendable: keep it isolated", explanation: tile.why))
        }
    }

    private func keep() {
        guard let tile, outcome == nil else { return }
        if tile.isSendable {
            outcome = .tooCautious
            misses.append(Miss(game: .dataRace, prompt: tile.code, answer: "Sendable: safe to send", explanation: tile.why))
        } else {
            score += 100
            correct += 1
            outcome = .safeKeep
            goodTick += 1
            autoAdvance()
        }
    }

    private func autoAdvance() {
        let current = index
        Task {
            try? await Task.sleep(for: .seconds(1.3))
            if index == current, outcome != nil, outcome?.isMistake == false { next() }
        }
    }

    private func next() {
        guard !finished else { return }
        if lives <= 0 || index + 1 >= tiles.count {
            finished = true
            onFinish(GameResult(game: .dataRace, score: score, correct: correct, total: index + 1, misses: misses))
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            outcome = nil
            drag = .zero
            index += 1
        }
    }

    // MARK: Pieces

    private struct DomainPanel: View {
        let title: String
        let subtitle: String
        let symbol: String
        let color: Color

        var body: some View {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(color.opacity(0.08))
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(color.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                Image(systemName: symbol)
                    .font(.system(size: 90, weight: .bold))
                    .foregroundStyle(color.opacity(0.08))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(.headline, design: .monospaced)).foregroundStyle(color)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private struct BoundaryWall: View {
        let vertical: Bool
        let flash: Outcome?

        var body: some View {
            let color: Color = switch flash {
            case .race: Palette.incorrect
            case .safeSend: Palette.correct
            default: .white
            }
            ZStack {
                Capsule()
                    .fill(color.opacity(flash == nil ? 0.18 : 0.55))
                    .frame(width: vertical ? 4 : nil, height: vertical ? nil : 4)
                    .shadow(color: color.opacity(0.8), radius: flash == nil ? 6 : 16)
                Text("isolation boundary")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Palette.canvas, in: .capsule)
                    .rotationEffect(.degrees(vertical ? -90 : 0))
            }
            .modifier(Shake(amount: flash == .race ? 1 : 0))
            .accessibilityHidden(true)
        }
    }

    private struct TileCard: View {
        let tile: RaceTile
        let outcome: Outcome?

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                CodeView(code: tile.code, size: 14, selectable: false)
                HStack(spacing: 6) {
                    Image(systemName: badgeSymbol)
                    Text(badgeText)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(badgeColor)
            }
            .padding(12)
            .background(Palette.raisedHigh, in: .rect(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(badgeColor.opacity(outcome == nil ? 0.25 : 0.8), lineWidth: outcome == nil ? 1 : 2)
            }
            .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Drag across the boundary to send it to the Store actor, or use the buttons below.")
        }

        private var badgeText: String {
            switch outcome {
            case .safeSend: "Sendable: crossed safely"
            case .safeKeep: "Kept isolated"
            case .race: "Data race!"
            case .tooCautious: "This one was safe to send"
            case nil: "Drag across to send"
            }
        }

        private var badgeSymbol: String {
            switch outcome {
            case .safeSend, .safeKeep: "checkmark.seal.fill"
            case .race: "exclamationmark.triangle.fill"
            case .tooCautious: "hand.raised.fill"
            case nil: "hand.draw.fill"
            }
        }

        private var badgeColor: Color {
            switch outcome {
            case .safeSend, .safeKeep: Palette.correct
            case .race: Palette.incorrect
            case .tooCautious: Palette.streak
            case nil: .secondary
            }
        }
    }

    private struct FeedbackCard: View {
        let tile: RaceTile
        let outcome: Outcome
        let onContinue: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                if outcome == .race {
                    Text("error: sending '\(tile.typeName)' risks causing data races")
                        .font(.system(.footnote, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Palette.incorrect)
                }
                Text(tile.why).font(.subheadline)
                if outcome.isMistake {
                    Button(action: onContinue) {
                        Text("Continue").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .surface(radius: 22, stroke: (outcome.isMistake ? Palette.incorrect : Palette.correct).opacity(0.4))
        }
    }
}
