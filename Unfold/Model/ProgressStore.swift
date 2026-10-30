import Foundation

/// XP, streaks, mastery and spaced-repetition boxes, saved as one JSON blob.
@Observable
final class ProgressStore {
    private struct Snapshot: Codable {
        var xp = 0
        var streak = 0
        var lastPlayed: Date?
        var mastery: [World: Double] = [:]
        var best: [GameID: Int] = [:]
        var plays = 0
        var recentMisses: [Miss] = []
        var cardBoxes: [String: Int] = [:]
    }

    private static let key = "unfold.progress.v1"
    private var snapshot: Snapshot {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = saved
        } else {
            snapshot = Snapshot()
        }
    }

    var xp: Int { snapshot.xp }
    var streak: Int { snapshot.streak }
    var plays: Int { snapshot.plays }
    var recentMisses: [Miss] { snapshot.recentMisses }
    var level: Int { snapshot.xp / 500 + 1 }
    var levelProgress: Double { Double(snapshot.xp % 500) / 500 }

    func mastery(_ world: World) -> Double { snapshot.mastery[world] ?? 0 }
    func best(_ game: GameID) -> Int? { snapshot.best[game] }

    /// Records a finished round and returns the XP it earned.
    @discardableResult
    func record(_ result: GameResult) -> Int {
        let earned = result.score / 10 + 20
        snapshot.xp += earned
        snapshot.plays += 1
        let world = GameInfo.info(result.game).world
        // A moving average, so mastery reflects recent rounds more than old ones.
        let previous = snapshot.mastery[world] ?? 0
        snapshot.mastery[world] = previous == 0 ? result.accuracy * 0.6 : previous * 0.7 + result.accuracy * 0.3
        snapshot.best[result.game] = max(snapshot.best[result.game] ?? 0, result.score)
        snapshot.recentMisses = Array((result.misses + snapshot.recentMisses).prefix(20))
        updateStreak()
        return earned
    }

    func isNewBest(_ result: GameResult) -> Bool {
        result.score > 0 && result.score >= (snapshot.best[result.game] ?? 0)
    }

    // MARK: Spaced repetition (Leitner boxes 0–4)

    func box(for cardID: String) -> Int { snapshot.cardBoxes[cardID] ?? 0 }

    func grade(cardID: String, knewIt: Bool) {
        snapshot.cardBoxes[cardID] = knewIt ? min(box(for: cardID) + 1, 4) : 0
    }

    /// Cards in the lowest boxes come first; ties are shuffled.
    func studyDeck(count: Int) -> [FlipCard] {
        let shuffled = Curriculum.cards.shuffled()
        return Array(shuffled.sorted { box(for: $0.id) < box(for: $1.id) }.prefix(count))
    }

    // MARK: Profile management

    func loadDemoProfile() {
        var demo = Snapshot()
        demo.xp = 1840
        demo.streak = 6
        demo.lastPlayed = .now
        demo.plays = 23
        demo.mastery = [.swift: 0.72, .frameworks: 0.54, .ecosystem: 0.86]
        demo.best = [.sprint: 2600, .dataRace: 1100, .flipCards: 800, .timeHinge: 640]
        demo.recentMisses = [
            Miss(game: .dataRace, prompt: "final class Logger { let id: UUID }", answer: "Not Sendable",
                 explanation: Curriculum.raceTiles[13].why),
            Miss(game: .sprint, prompt: "guard without an exit", answer: "No, guard's else must exit",
                 explanation: Curriculum.sprint[20].explanation),
        ]
        snapshot = demo
    }

    func reset() {
        snapshot = Snapshot()
    }

    private func updateStreak() {
        let calendar = Calendar.current
        if let last = snapshot.lastPlayed {
            if calendar.isDateInToday(last) {
                snapshot.streak = max(snapshot.streak, 1)
            } else if calendar.isDateInYesterday(last) {
                snapshot.streak += 1
            } else {
                snapshot.streak = 1
            }
        } else {
            snapshot.streak = 1
        }
        snapshot.lastPlayed = .now
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
