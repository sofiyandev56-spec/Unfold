import SwiftUI

enum GameID: String, CaseIterable, Identifiable, Codable {
    case sprint, dataRace, flipCards, timeHinge

    var id: String { rawValue }
}

struct GameInfo: Identifiable {
    let id: GameID
    let title: String
    let tagline: String
    let world: World
    let symbol: String
    /// Three colours for key art, from brightest to deepest.
    let colors: [Color]
    let foldTitle: String
    let foldDetail: String
    let rules: [String]
    let length: String

    static let all: [GameInfo] = [
        GameInfo(
            id: .flipCards,
            title: "Fold & Flip",
            tagline: "Flashcards that turn with your phone.",
            world: .frameworks,
            symbol: "rectangle.stack.fill",
            colors: [Color(.displayP3, red: 0.30, green: 0.88, blue: 0.95),
                     Color(.displayP3, red: 0.16, green: 0.52, blue: 1.00),
                     Color(.displayP3, red: 0.10, green: 0.25, blue: 0.55)],
            foldTitle: "Fold to flip",
            foldDetail: "Bend the hinge and the card turns on the same axis as your phone, revealing the answer. Unfold to deal the next card.",
            rules: ["Read the task and recall the Apple framework that does it.",
                    "Fold the phone, drag, or tap to flip the card.",
                    "Rate yourself. Spaced repetition brings back what you missed."],
            length: "10 cards"
        ),
        GameInfo(
            id: .timeHinge,
            title: "Time Hinge",
            tagline: "Fold through fifty years of Apple.",
            world: .ecosystem,
            symbol: "clock.arrow.circlepath",
            colors: [Color(.displayP3, red: 0.80, green: 0.55, blue: 1.00),
                     Color(.displayP3, red: 0.45, green: 0.30, blue: 0.95),
                     Color(.displayP3, red: 0.20, green: 0.10, blue: 0.45)],
            foldTitle: "Your hinge is the dial",
            foldDetail: "The hinge angle sweeps a protractor from 1976 to 2026. Hold the phone steady on the right year to lock it in.",
            rules: ["Read the moment in Apple history.",
                    "Fold the phone, or drag the dial, to pick the year.",
                    "Hold steady to lock. Closer guesses score more."],
            length: "8 rounds"
        ),
        GameInfo(
            id: .dataRace,
            title: "Data Race",
            tagline: "Guard the isolation boundary.",
            world: .swift,
            symbol: "shield.lefthalf.filled",
            colors: [Color(.displayP3, red: 1.00, green: 0.38, blue: 0.45),
                     Color(.displayP3, red: 0.95, green: 0.25, blue: 0.70),
                     Color(.displayP3, red: 0.35, green: 0.08, blue: 0.35)],
            foldTitle: "The crease is the boundary",
            foldDetail: "On iPhone Duo the fold becomes the wall between @MainActor and actor Store. Only Sendable values may cross it.",
            rules: ["Drag Sendable values across the boundary.",
                    "Keep values that aren't Sendable on their own side.",
                    "Three data races and the round is over."],
            length: "12 values"
        ),
        GameInfo(
            id: .sprint,
            title: "Swift Sprint",
            tagline: "Read the code. Beat the clock.",
            world: .swift,
            symbol: "bolt.fill",
            colors: [Color(.displayP3, red: 1.00, green: 0.62, blue: 0.20),
                     Color(.displayP3, red: 1.00, green: 0.33, blue: 0.18),
                     Color(.displayP3, red: 0.45, green: 0.10, blue: 0.05)],
            foldTitle: "Laptop mode",
            foldDetail: "Half-fold the inner display and the code rises to the top half while the answers drop to the bottom, like a keyboard.",
            rules: ["Predict the output, or decide whether it compiles.",
                    "Answer streaks multiply your score, up to five times.",
                    "Every mistake explains itself, then Coach reviews them."],
            length: "60 seconds"
        ),
    ]

    static func info(_ id: GameID) -> GameInfo {
        all.first { $0.id == id }!
    }

    /// A different headline game each day.
    static var featured: GameInfo {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[day % all.count]
    }
}

/// What a finished round reports back to the host, the progress store and Coach.
struct GameResult: Identifiable {
    let id = UUID()
    let game: GameID
    let score: Int
    let correct: Int
    let total: Int
    let misses: [Miss]

    var accuracy: Double { total == 0 ? 0 : Double(correct) / Double(total) }
}

struct Miss: Identifiable, Codable, Hashable {
    var id = UUID()
    let game: GameID
    let prompt: String
    let answer: String
    let explanation: String
}
