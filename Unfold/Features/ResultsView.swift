import SwiftUI

struct ResultsView: View {
    let game: GameInfo
    let result: GameResult
    let xp: Int
    let newBest: Bool
    let onReplay: () -> Void
    let onDone: () -> Void

    @Environment(Coach.self) private var coach
    @Environment(Router.self) private var router
    @State private var shownScore = 0
    @State private var debrief = ""
    @State private var celebrate = 0

    private var verdict: String {
        switch result.accuracy {
        case 0.95...: "Flawless"
        case 0.8..<0.95: "Sharp work"
        case 0.6..<0.8: "Solid round"
        default: "Keep folding"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text(verdict).eyebrow(game.colors[0])
                    Text("\(shownScore)")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText(value: Double(shownScore)))
                        .monospacedDigit()
                    Text("points in \(game.title)").foregroundStyle(.secondary)
                    if newBest {
                        Label("New personal best", systemImage: "crown.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.streak)
                            .padding(.top, 4)
                            .symbolEffect(.bounce, value: celebrate)
                    }
                }
                .padding(.top, 40)

                HStack(spacing: 12) {
                    StatTile(value: "\(result.correct)/\(result.total)", caption: "Correct")
                    StatTile(value: "\(Int((result.accuracy * 100).rounded()))%", caption: "Accuracy", color: game.world.color)
                    StatTile(value: "+\(xp)", caption: "XP earned", color: Palette.streak)
                }

                debriefCard

                if !result.misses.isEmpty {
                    missesSection
                }

                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: onDone) {
                            Text("Done").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        Button(action: onReplay) {
                            Label("Play Again", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(game.colors[1])
                    }
                    .controlSize(.extraLarge)
                    .font(.headline)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .sensoryFeedback(.success, trigger: celebrate)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.smooth(duration: 1.0)) { shownScore = result.score }
            celebrate += 1
            await coach.debrief(result) { debrief = $0 }
        }
    }

    private var debriefCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CoachMark(size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Coach's debrief").font(.rounded(.headline))
                    Text(coach.isLive ? "Apple Intelligence · on device" : "From Unfold's notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if debrief.isEmpty {
                Label("Reviewing your round…", systemImage: "ellipsis")
                    .symbolEffect(.variableColor.iterative)
                    .foregroundStyle(.secondary)
            } else {
                Text(debrief)
                    .font(.body)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: debrief)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: .rect(cornerRadius: 24, style: .continuous))
        .intelligenceGlow(radius: 24, active: coach.isLive)
    }

    private var missesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Worth another look").font(.rounded(.headline))
            ForEach(result.misses.prefix(5)) { miss in
                VStack(alignment: .leading, spacing: 8) {
                    Text(miss.prompt)
                        .font(.system(.subheadline, design: .monospaced))
                        .lineLimit(3)
                    Label(miss.answer, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.correct)
                    Text(miss.explanation).font(.subheadline).foregroundStyle(.secondary)
                    Button {
                        router.ask("Help me understand this: \(miss.prompt). The correct answer is \(miss.answer).")
                        onDone()
                    } label: {
                        Label("Ask Coach", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .tint(Palette.intelligence[1])
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .surface(radius: 20)
            }
        }
    }
}
