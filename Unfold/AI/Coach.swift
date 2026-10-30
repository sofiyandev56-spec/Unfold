import FoundationModels
import SwiftUI

/// Unfold's tutor, powered by the on-device Apple Intelligence model.
///
/// Everything runs locally through FoundationModels, so a student's questions never leave
/// the phone. When the model isn't available, Coach answers from the curriculum instead.
@Observable
final class Coach {
    struct Message: Identifiable, Equatable {
        enum Role { case student, coach }
        let id = UUID()
        let role: Role
        var text: String
    }

    enum Status: Equatable {
        case live
        case offline(String)
    }

    private(set) var status: Status
    private(set) var messages: [Message] = []
    private(set) var isResponding = false
    private var session: LanguageModelSession?

    static let instructions = """
        You are Coach, a warm, expert mentor inside Unfold, a learning arcade about Apple. \
        You teach Swift, SwiftUI, Apple frameworks, Swift concurrency, Liquid Glass design and Apple history. \
        Answer in at most 120 words. Prefer one short Swift example when it helps. \
        Be precise and encouraging. If you are not sure, say so rather than guessing.
        """

    init() {
        switch SystemLanguageModel.default.availability {
        case .available:
            status = .live
        case .unavailable(.deviceNotEligible):
            status = .offline("This device doesn't support Apple Intelligence, so Coach is answering from Unfold's notes.")
        case .unavailable(.appleIntelligenceNotEnabled):
            status = .offline("Turn on Apple Intelligence in Settings for live answers. Until then Coach uses Unfold's notes.")
        case .unavailable(.modelNotReady):
            status = .offline("Apple Intelligence is still getting ready. Coach is using Unfold's notes for now.")
        case .unavailable:
            status = .offline("Apple Intelligence is unavailable, so Coach is answering from Unfold's notes.")
        @unknown default:
            status = .offline("Apple Intelligence is unavailable, so Coach is answering from Unfold's notes.")
        }
    }

    var isLive: Bool { status == .live }

    /// Warms the model so the first answer starts quickly.
    func prepare() {
        guard isLive, session == nil else { return }
        let session = LanguageModelSession(instructions: Self.instructions)
        session.prewarm()
        self.session = session
    }

    func ask(_ question: String) async {
        let text = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        messages.append(Message(role: .student, text: text))
        messages.append(Message(role: .coach, text: ""))
        let index = messages.count - 1
        isResponding = true
        defer { isResponding = false }

        guard isLive else {
            messages[index].text = OfflineNotes.answer(to: text)
            return
        }
        do {
            let session = self.session ?? LanguageModelSession(instructions: Self.instructions)
            self.session = session
            for try await snapshot in session.streamResponse(to: OfflineNotes.grounded(text)) {
                messages[index].text = snapshot.content
            }
        } catch {
            // A fresh session next time, in case the context window filled up.
            self.session = nil
            messages[index].text = OfflineNotes.answer(to: text)
        }
    }

    /// Streams a short, personal review of a finished round.
    func debrief(_ result: GameResult, update: (String) -> Void) async {
        let fallback = OfflineNotes.debrief(result)
        guard isLive else {
            update(fallback)
            return
        }
        let game = GameInfo.info(result.game)
        let mistakes = result.misses.prefix(4).map { "- \($0.prompt) → correct answer: \($0.answer)" }.joined(separator: "\n")
        let prompt = """
            The student just played \(game.title) (\(game.world.title)) and got \(result.correct) of \(result.total) right.
            Their mistakes:
            \(mistakes.isEmpty ? "none" : mistakes)
            Write three short sentences: one specific piece of praise, the single most important idea \
            to fix with a crisp explanation, and one tip for next time. No headings or lists.
            """
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            for try await snapshot in session.streamResponse(to: prompt) {
                update(snapshot.content)
            }
        } catch {
            update(fallback)
        }
    }

    func clear() {
        messages.removeAll()
        session = nil
    }
}

/// Retrieval over Unfold's own curriculum: it grounds the live model and answers on its own offline.
enum OfflineNotes {
    /// Notes ranked by how many of the question's words they share.
    static func relevant(to question: String) -> [Note] {
        let words = Set(question.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 })

        func score(_ note: Note) -> Int {
            let haystack = (note.title + " " + note.body).lowercased()
            return words.reduce(0) { $0 + (haystack.contains($1) ? 1 : 0) }
        }

        let ranked = Curriculum.notes.map { ($0, score($0)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
        // Keep only close runners-up; a one-word match drags answers off topic.
        let cutoff = max((ranked.first?.1 ?? 0) - 1, 1)
        return ranked.filter { $0.1 >= cutoff }.map(\.0)
    }

    /// The question plus the closest curriculum notes, so the on-device model can answer
    /// about APIs newer than its training, like iPhone Duo's hinge.
    static func grounded(_ question: String) -> String {
        let notes = relevant(to: question).prefix(2)
        guard !notes.isEmpty else { return question }
        let context = notes.map { "- \($0.title): \($0.body)" }.joined(separator: "\n")
        return """
            \(question)

            Reference notes from Unfold's curriculum. Prefer them over memory when they apply:
            \(context)
            """
    }

    static func answer(to question: String) -> String {
        let ranked = relevant(to: question)
        guard let best = ranked.first else {
            return "I don't have notes on that yet. Try asking about Swift optionals, actors and Sendable, SwiftUI state, Apple frameworks, or a moment in Apple history."
        }
        var reply = "**\(best.title)**\n\(best.body)"
        if let next = ranked.dropFirst().first {
            reply += "\n\nRelated: **\(next.title)**. \(next.body)"
        }
        return reply
    }

    static func debrief(_ result: GameResult) -> String {
        let game = GameInfo.info(result.game)
        let percent = Int((result.accuracy * 100).rounded())
        guard let miss = result.misses.first else {
            return "A clean round of \(game.title): \(percent)% correct. Try it again faster, or move on to a world you haven't mastered yet."
        }
        return "You got \(percent)% in \(game.title). The idea to revisit: \(miss.explanation) Ask me about it if it still feels fuzzy."
    }
}
