import SwiftUI

/// Where a push came from, so the zoom transition grows out of the right card.
struct GameRoute: Hashable {
    let game: GameID
    let source: String
}

struct ArcadeView: View {
    @Environment(ProgressStore.self) private var progress
    @Namespace private var zoom
    @State private var width: CGFloat = 400
    @State private var directPlay: GameInfo?

    private var featured: GameInfo { GameInfo.featured }
    private var isWide: Bool { width >= 560 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    greeting

                    NavigationLink(value: GameRoute(game: featured.id, source: "hero")) {
                        HeroCard(game: featured, tall: !isWide)
                    }
                    .buttonStyle(PressableStyle())
                    .matchedTransitionSource(id: "hero", in: zoom)

                    section("Built for the fold", detail: "Every game is played with the hinge") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: isWide ? 4 : 2), spacing: 20) {
                            ForEach(GameInfo.all) { game in
                                NavigationLink(value: GameRoute(game: game.id, source: "tile-\(game.id.rawValue)")) {
                                    GameTile(game: game, best: progress.best(game.id))
                                }
                                .buttonStyle(PressableStyle())
                                .matchedTransitionSource(id: "tile-\(game.id.rawValue)", in: zoom)
                            }
                        }
                    }

                    section("Your worlds", detail: "Mastery grows with every round") {
                        HStack(spacing: 12) {
                            ForEach(World.allCases) { world in
                                WorldCard(world: world, mastery: progress.mastery(world))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .background(Palette.canvas)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle("Arcade")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PresenterToggle()
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(progress.streak)", systemImage: "flame.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.streak)
                        .accessibilityLabel("\(progress.streak) day streak")
                }
            }
            .navigationDestination(for: GameRoute.self) { route in
                GameDetailView(game: .info(route.game))
                    .navigationTransition(.zoom(sourceID: route.source, in: zoom))
            }
            .fullScreenCover(item: $directPlay) { game in
                GameHost(game: game)
            }
            .task {
                // `-play <game>` opens a game straight away, for stage demos.
                let arguments = ProcessInfo.processInfo.arguments
                if let flag = arguments.firstIndex(of: "-play"), flag + 1 < arguments.count,
                   let id = GameID(rawValue: arguments[flag + 1]) {
                    directPlay = .info(id)
                }
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                .eyebrow()
            Text("Learn Apple, one fold at a time.")
                .font(.rounded(.title3, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func section<Content: View>(_ title: String, detail: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.rounded(.title2))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            content()
        }
    }
}

/// The day's headline game, full-bleed like an Apple Arcade feature.
struct HeroCard: View {
    let game: GameInfo
    var tall = true

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            KeyArt(game: game, glyphSize: tall ? 170 : 200, glyphAlignment: .topTrailing)

            VStack(alignment: .leading, spacing: 10) {
                Text("Today's game").eyebrow(.white.opacity(0.75))
                Text(game.title)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(game.tagline)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                HStack(spacing: 12) {
                    Label("Play", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.tint(game.colors[1].opacity(0.6)).interactive(), in: .capsule)
                    Label(game.foldTitle, systemImage: "book.pages")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 6)
            }
            .padding(26)
        }
        .frame(height: tall ? 440 : 380)
        .clipShape(.rect(cornerRadius: 34, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous).strokeBorder(.white.opacity(0.12))
        }
        .shadow(color: game.colors[1].opacity(0.35), radius: 30, y: 18)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's game, \(game.title). \(game.tagline)")
    }
}

struct GameTile: View {
    let game: GameInfo
    let best: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KeyArt(game: game, animated: false, glyphSize: 86)
                .frame(height: 164)
                .clipShape(.rect(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.1))
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(game.title)
                    .font(.rounded(.headline))
                    .foregroundStyle(.primary)
                Text(game.foldTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let best {
                    Label("\(best)", systemImage: "crown.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.streak)
                }
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .combine)
    }
}

struct WorldCard: View {
    let world: World
    let mastery: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RingStack(values: [(mastery, world.color)], lineWidth: 8)
                .frame(width: 58, height: 58)
                .overlay {
                    Text("\(Int((mastery * 100).rounded()))")
                        .font(.rounded(.caption, weight: .heavy))
                        .monospacedDigit()
                }
            Text(world.title)
                .font(.rounded(.subheadline))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .surface(radius: 24, stroke: world.color.opacity(0.25))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(world.title), \(Int((mastery * 100).rounded())) percent mastered")
    }
}
