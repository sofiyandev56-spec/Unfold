import SwiftUI

struct SearchView: View {
    @State private var query = ""

    private var results: [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Curriculum.notes }
        return Curriculum.notes.filter {
            $0.title.localizedStandardContains(trimmed) || $0.body.localizedStandardContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(World.allCases) { world in
                    let notes = results.filter { $0.world == world }
                    if !notes.isEmpty {
                        Section {
                            ForEach(notes) { note in
                                NavigationLink {
                                    NoteDetail(note: note)
                                } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(note.title).font(.body.weight(.medium))
                                        Text(note.body).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                }
                            }
                        } header: {
                            Label(world.title, systemImage: world.symbol).foregroundStyle(world.color)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.canvas)
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, prompt: "Swift, frameworks, Apple history")
            .navigationTitle("Search")
        }
    }
}

struct NoteDetail: View {
    let note: Note
    @Environment(Router.self) private var router

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                WorldChip(world: note.world)
                Text(note.title).font(.rounded(.largeTitle, weight: .heavy))
                Text(note.body).font(.title3)
                Button {
                    router.ask("Tell me more about \(note.title). \(note.body)")
                } label: {
                    Label("Ask Coach about this", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .padding(.top, 8)
            }
            .padding(20)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.canvas)
        .navigationBarTitleDisplayMode(.inline)
    }
}
