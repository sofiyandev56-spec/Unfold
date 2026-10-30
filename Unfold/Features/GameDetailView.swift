import SwiftUI

struct GameDetailView: View {
    let game: GameInfo

    @Environment(ProgressStore.self) private var progress
    @Environment(FoldState.self) private var fold
    @State private var playing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                KeyArt(game: game, glyphSize: 190, glyphAlignment: .topTrailing)
                    .frame(height: 430)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            WorldChip(world: game.world)
                                .background(.black.opacity(0.35), in: .capsule)
                            Text(game.title)
                                .font(.system(size: 46, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text(game.tagline)
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(24)
                    }

                VStack(alignment: .leading, spacing: 22) {
                    Button {
                        playing = true
                    } label: {
                        Label("Play · \(game.length)", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.extraLarge)
                    .tint(game.colors[1])

                    foldCard
                    rulesCard

                    if let best = progress.best(game.id) {
                        HStack(spacing: 12) {
                            StatTile(value: "\(best)", caption: "Personal best", color: Palette.streak)
                            StatTile(value: "\(Int((progress.mastery(game.world) * 100).rounded()))%",
                                     caption: "\(game.world.title) mastery", color: game.world.color)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Palette.canvas)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { PresenterToggle() }
        }
        .fullScreenCover(isPresented: $playing) {
            GameHost(game: game)
        }
    }

    private var foldCard: some View {
        HStack(alignment: .top, spacing: 18) {
            PhaseAnimator([180.0, 95.0]) { angle in
                HingeGlyph(angle: angle)
                    .stroke(game.colors[0], style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 64, height: 40)
            } animation: { _ in
                .easeInOut(duration: 1.6)
            }
            .frame(width: 64, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text("iPhone Duo").eyebrow(game.colors[0])
                Text(game.foldTitle).font(.rounded(.title3))
                Text(game.foldDetail).font(.subheadline).foregroundStyle(.secondary)
                Text(hingeStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(stroke: game.colors[0].opacity(0.3))
    }

    private var hingeStatus: String {
        switch fold.source {
        case .hardware where fold.pose == .closed: "iPhone Duo is closed. Touch controls work here; open it to play with the hinge."
        case .hardware: "Live hinge detected: \(Int(fold.angle ?? 0))°"
        case .presenter: "Presenter hinge is on"
        case .none: "No hinge on this iPhone. Drag and tap controls take over."
        }
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to play").font(.rounded(.headline))
            ForEach(Array(game.rules.enumerated()), id: \.offset) { index, rule in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.rounded(.subheadline, weight: .heavy))
                        .foregroundStyle(game.colors[0])
                        .frame(width: 22)
                    Text(rule).font(.body)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface()
    }
}
