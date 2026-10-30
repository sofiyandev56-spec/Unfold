import SwiftUI

struct JourneyView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(FoldState.self) private var fold
    @Environment(Coach.self) private var coach
    @Environment(\.windowSize) private var window
    @State private var confirmReset = false

    var body: some View {
        @Bindable var fold = fold
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ringsCard
                    levelCard

                    HStack(spacing: 12) {
                        StatTile(value: "\(progress.streak)", caption: "Day streak", color: Palette.streak)
                        StatTile(value: "\(progress.plays)", caption: "Rounds played")
                        StatTile(value: "\(progress.xp)", caption: "Total XP")
                    }

                    bestScores

                    deviceCard

                    VStack(spacing: 0) {
                        Toggle(isOn: $fold.presenterEnabled.animation(.smooth)) {
                            Label("Presenter hinge", systemImage: "slider.horizontal.below.rectangle")
                        }
                        .padding(16)
                        Divider().padding(.leading, 16)
                        Button {
                            withAnimation(.smooth) { progress.loadDemoProfile() }
                        } label: {
                            Label("Load demo profile", systemImage: "person.crop.circle.badge.checkmark")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        Divider().padding(.leading, 16)
                        Button(role: .destructive) {
                            confirmReset = true
                        } label: {
                            Label("Reset progress", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .confirmationDialog("Reset all progress?", isPresented: $confirmReset) {
                            Button("Reset", role: .destructive) {
                                withAnimation(.smooth) { progress.reset() }
                            }
                        } message: {
                            Text("XP, streaks, mastery and flashcard history will be cleared.")
                        }
                    }
                    .surface(radius: 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.canvas)
            .navigationTitle("Journey")
        }
    }

    private var ringsCard: some View {
        HStack(spacing: 24) {
            RingStack(values: World.allCases.map { (progress.mastery($0), $0.color) }, lineWidth: 18, gap: 4)
                .frame(width: 156, height: 156)
                .id(progress.xp)
            VStack(alignment: .leading, spacing: 14) {
                ForEach(World.allCases) { world in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(world.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(world.color)
                        Text("\(Int((progress.mastery(world) * 100).rounded()))%")
                            .font(.rounded(.title3, weight: .heavy))
                            .monospacedDigit()
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .surface()
        .accessibilityElement(children: .combine)
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Level \(progress.level)").font(.rounded(.title2, weight: .heavy))
                Spacer()
                Text("\(500 - progress.xp % 500) XP to level \(progress.level + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress.levelProgress)
                .tint(Palette.streak)
                .scaleEffect(y: 1.6)
        }
        .padding(20)
        .surface()
    }

    private var bestScores: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Personal bests").font(.rounded(.headline)).padding([.horizontal, .top], 18).padding(.bottom, 6)
            ForEach(GameInfo.all) { game in
                HStack(spacing: 14) {
                    Image(systemName: game.symbol)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(LinearGradient(colors: [game.colors[0], game.colors[1]], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: .rect(cornerRadius: 10, style: .continuous))
                    Text(game.title).font(.body.weight(.medium))
                    Spacer()
                    Text(progress.best(game.id).map(String.init) ?? "–")
                        .font(.rounded(.headline))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
            .padding(.bottom, 8)
        }
        .surface(radius: 24)
    }

    private var deviceCard: some View {
        HStack(spacing: 16) {
            HingeGlyph(angle: fold.angle ?? 180)
                .stroke(Palette.tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .frame(width: 52, height: 32)
                .animation(.interactiveSpring, value: fold.angle)
            VStack(alignment: .leading, spacing: 3) {
                Text("Hinge").font(.rounded(.headline))
                Text(hingeDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(18)
        .surface(radius: 24)
    }

    private var hingeDescription: String {
        switch fold.source {
        case .hardware: "Live from iPhone Duo · \(Int(fold.angle ?? 0))° · \(fold.poseName(isLandscape: window.isLandscape))"
        case .presenter: "Presenter hinge · \(Int(fold.angle ?? 0))°"
        case .none: "No hinge on this iPhone. Turn on the presenter hinge to try fold play."
        }
    }
}
