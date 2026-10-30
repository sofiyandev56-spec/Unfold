import SwiftUI

/// Runs one game full screen, then shows its results.
///
/// Game state lives in the game's own view, which keeps its identity when the window
/// resizes, so a round carries on uninterrupted as iPhone Duo folds and unfolds.
struct GameHost: View {
    let game: GameInfo

    @Environment(\.dismiss) private var dismiss
    @Environment(ProgressStore.self) private var progress
    @Environment(FoldState.self) private var fold
    @State private var result: GameResult?
    @State private var earnedXP = 0
    @State private var newBest = false
    @State private var round = 0
    @State private var toast: String?
    @State private var isLandscape = false

    var body: some View {
        ZStack {
            if let result {
                ResultsView(game: game, result: result, xp: earnedXP, newBest: newBest,
                            onReplay: replay, onDone: { dismiss() })
                    .transition(.asymmetric(insertion: .scale(scale: 0.94).combined(with: .opacity),
                                            removal: .opacity))
            } else {
                VStack(spacing: 0) {
                    gameView
                        .id(round)
                    if fold.presenterEnabled {
                        PresenterHingeBar()
                            .padding(.bottom, 6)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { GameBackdrop(colors: game.colors) }
        .overlay(alignment: .top) {
            if let toast {
                PoseToast(name: toast, angle: fold.angle ?? 180)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: { isLandscape = $0 }
        .onChange(of: fold.pose) { _, _ in announcePose() }
        .animation(.smooth(duration: 0.45), value: result?.id)
        .animation(.smooth, value: fold.presenterEnabled)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var gameView: some View {
        switch game.id {
        case .sprint: SprintGame(onFinish: finish, onQuit: quit)
        case .dataRace: DataRaceGame(onFinish: finish, onQuit: quit)
        case .flipCards: FlipCardsGame(onFinish: finish, onQuit: quit)
        case .timeHinge: TimeHingeGame(onFinish: finish, onQuit: quit)
        }
    }

    private func finish(_ outcome: GameResult) {
        newBest = progress.isNewBest(outcome)
        earnedXP = progress.record(outcome)
        withAnimation(.smooth(duration: 0.45)) { result = outcome }
    }

    private func replay() {
        withAnimation(.smooth(duration: 0.45)) {
            result = nil
            round += 1
        }
    }

    private func quit() { dismiss() }

    private func announcePose() {
        guard fold.source != .none, result == nil else { return }
        let name = fold.poseName(isLandscape: isLandscape)
        withAnimation(.smooth) { toast = name }
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            if toast == name { withAnimation(.smooth) { toast = nil } }
        }
    }
}
