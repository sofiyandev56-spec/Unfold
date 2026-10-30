import SwiftUI

struct CoachView: View {
    @Environment(Coach.self) private var coach
    @Environment(Router.self) private var router
    @Environment(ProgressStore.self) private var progress
    @State private var draft = ""
    @FocusState private var composing: Bool

    private let suggestions = [
        "Explain Sendable like I'm new to Swift",
        "When should I reach for an actor?",
        "What is Liquid Glass, and where should I use it?",
        "How does @Observable know what to refresh?",
        "Why did Apple move the Mac to Apple silicon?",
        "How do I react to iPhone Duo's hinge in SwiftUI?",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    statusCard
                    if coach.messages.isEmpty {
                        suggestionList
                        if !progress.recentMisses.isEmpty { reviewList }
                    }
                    ForEach(coach.messages) { message in
                        MessageRow(message: message,
                                   streaming: coach.isResponding && message.id == coach.messages.last?.id,
                                   live: coach.isLive)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
                .animation(.smooth, value: coach.messages.count)
            }
            .defaultScrollAnchor(coach.messages.isEmpty ? .top : .bottom)
            .scrollDismissesKeyboard(.interactively)
            .background(Palette.canvas)
            .safeAreaInset(edge: .bottom) { composer }
            .navigationTitle("Coach")
            .toolbar {
                if !coach.messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("New chat", systemImage: "square.and.pencil") {
                            withAnimation(.smooth) { coach.clear() }
                        }
                    }
                }
            }
            .onChange(of: router.pendingQuestion, initial: true) { _, question in
                guard let question else { return }
                router.pendingQuestion = nil
                Task { await coach.ask(question) }
            }
        }
    }

    private var statusCard: some View {
        HStack(alignment: .top, spacing: 14) {
            CoachMark(size: 40)
            VStack(alignment: .leading, spacing: 4) {
                switch coach.status {
                case .live:
                    Text("Apple Intelligence · On device").font(.rounded(.headline))
                    Text("Private by design: your questions never leave this iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                case .offline(let reason):
                    Text("Offline notes").font(.rounded(.headline))
                    Text(reason).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.raised, in: .rect(cornerRadius: 24, style: .continuous))
        .intelligenceGlow(radius: 24, active: coach.isLive)
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Try asking").font(.rounded(.headline)).padding(.top, 6)
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    Task { await coach.ask(suggestion) }
                } label: {
                    HStack {
                        Text(suggestion).multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right").foregroundStyle(.tertiary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(16)
                    .surface(radius: 18)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private var reviewList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review your recent misses").font(.rounded(.headline)).padding(.top, 6)
            ForEach(progress.recentMisses.prefix(3)) { miss in
                Button {
                    Task { await coach.ask("Help me understand this: \(miss.prompt). The correct answer is \(miss.answer).") }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(miss.prompt).font(.system(.subheadline, design: .monospaced)).lineLimit(2)
                        Text(miss.answer).font(.caption.weight(.semibold)).foregroundStyle(Palette.correct)
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .surface(radius: 18)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private var composer: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                TextField("Ask about Swift, SwiftUI or Apple…", text: $draft)
                    .focused($composing)
                    .submitLabel(.send)
                    .onSubmit(send)
                    .padding(.horizontal, 18)
                    .frame(height: 50)
                    .glassEffect(.regular.interactive(), in: .capsule)

                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(Palette.tint).interactive(), in: .circle)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || coach.isResponding)
                .opacity(draft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                .accessibilityLabel("Send")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func send() {
        let question = draft
        draft = ""
        Task { await coach.ask(question) }
    }
}

struct MessageRow: View {
    let message: Coach.Message
    let streaming: Bool
    let live: Bool

    var body: some View {
        switch message.role {
        case .student:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Palette.tint, in: .rect(cornerRadius: 22, style: .continuous))
            }
        case .coach:
            HStack(alignment: .top, spacing: 10) {
                CoachMark(size: 30)
                Group {
                    if message.text.isEmpty {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .symbolEffect(.variableColor.iterative)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        Text(Self.render(message.text))
                            .textSelection(.enabled)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.raised, in: .rect(cornerRadius: 22, style: .continuous))
                .intelligenceGlow(radius: 22, active: live && streaming)
            }
        }
    }

    /// Inline Markdown for prose; lines inside code fences get monospaced, Xcode-coloured type.
    static func render(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        var result = AttributedString()
        var inCode = false
        for (index, line) in text.components(separatedBy: "\n").enumerated() {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                inCode.toggle()
                continue
            }
            if index > 0, !result.characters.isEmpty { result += AttributedString("\n") }
            if inCode {
                var code = SwiftHighlighter.highlight(line)
                code.font = .system(.callout, design: .monospaced)
                result += code
            } else {
                result += (try? AttributedString(markdown: line, options: options)) ?? AttributedString(line)
            }
        }
        return result
    }
}
