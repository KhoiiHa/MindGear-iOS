import SwiftUI
import SwiftData

struct VideoListView: View {
    let playlistID: String // Playlist-ID für Debugging speichern
    private let context: ModelContext
    @StateObject private var viewModel: VideoViewModel
    @State private var isPlaylistFavorite: Bool = false

    // Expliziter Initializer: setzt Playlist-ID und erstellt das ViewModel mit SwiftData-Context
    init(playlistID: String, context: ModelContext) {
        self.playlistID = playlistID
        self.context = context
        _viewModel = StateObject(
            wrappedValue: VideoViewModel(
                playlistId: playlistID,
                context: context
            )
        )
    }

    // Separate Binding für den Alert, entlastet den Typsystem-Checker
    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in if !newValue { viewModel.errorMessage = nil } }
        )
    }

    // Explizite Bindings entlasten die Dynamik von $viewModel
    private var favoritesOnlyBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showFavoritesOnly },
            set: { viewModel.showFavoritesOnly = $0 }
        )
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { viewModel.searchText = $0 }
        )
    }

    // Autovervollständigung: einfache, lokale Vorschlagslogik auf Basis der gefilterten Videos
    private var suggestionItems: [String] {
        let q = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = q.lowercased()
        guard query.count >= 2 else { return [] }

        // Kandidaten: aktuelle (bereits gefilterte) Titel – leichtgewichtig und offline-freundlich
        let titles = viewModel.filteredVideos.map { $0.title }

        // Priorisierung: Prefix-Treffer vor "contains"-Treffern, Duplikate entfernen, max. 6
        let prefix = titles.filter { $0.lowercased().hasPrefix(query) }
        let rest = titles.filter { $0.lowercased().contains(query) && !$0.lowercased().hasPrefix(query) }
        var merged: [String] = []
        for t in (prefix + rest) {
            if !merged.contains(t) { merged.append(t) }
        }
        return Array(merged.prefix(6))
    }

    private func togglePlaylistFavorite() {
        let derivedTitle = viewModel.playlistTitle.isEmpty ? "Playlist" : viewModel.playlistTitle
        let derivedThumb = viewModel.playlistThumbnailURL
        Task { @MainActor in
            await FavoritesManager.shared.togglePlaylistFavorite(
                id: playlistID,
                title: derivedTitle,
                thumbnailURL: derivedThumb,
                context: context
            )
            // Nur Status aktualisieren, keine Liste neu laden
            isPlaylistFavorite = FavoritesManager.shared.isPlaylistFavorite(id: playlistID, context: context)
        }
    }

    // Ausgelagerte Liste zur Entlastung der Typinferenz
    private var videosList: some View {
        List {
            ForEach(viewModel.filteredVideos) { (video: Video) in
                NavigationLink(destination: VideoDetailView(video: video, context: context)) {
                    HStack {
                        VideoRow(video: video)
                        Spacer()
                        Button {
                            togglePlaylistFavorite()
                        } label: {
                            Image(systemName: isPlaylistFavorite ? "star.fill" : "star")
                                .foregroundColor(isPlaylistFavorite ? .yellow : .gray)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isPlaylistFavorite ? "Playlist als Favorit entfernt" : "Playlist als Favorit hinzugefügt")
                    }
                }
                .onAppear {
                    // Infinite Scroll entfernt - kein Nachladen mehr hier
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                videosList
                    .navigationTitle("Videos")
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Toggle(isOn: favoritesOnlyBinding) {
                                Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                                    .foregroundColor(viewModel.showFavoritesOnly ? .red : .gray)
                            }
                            .toggleStyle(.button)
                            .accessibilityLabel("Nur Favoriten anzeigen")

                            Button {
                                togglePlaylistFavorite()
                            } label: {
                                Image(systemName: isPlaylistFavorite ? "star.fill" : "star")
                                    .foregroundColor(isPlaylistFavorite ? .yellow : .gray)
                            }
                            .accessibilityLabel("Playlist favorisieren")
                        }
                    }
                    .searchable(text: searchTextBinding, prompt: "Suche Videos")
                    .searchSuggestions {
                        // Wenn der Nutzer bereits tippt (>=2 Zeichen) → dynamische Vorschläge
                        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.count >= 2 {
                            ForEach(suggestionItems, id: \.self) { suggestion in
                                Button(action: {
                                    viewModel.searchText = suggestion
                                    viewModel.updateQuery(suggestion)
                                    viewModel.commitSearchTerm() // ausgewählten Vorschlag speichern
                                }) {
                                    Text(suggestion)
                                }
                                .searchCompletion(suggestion)
                            }
                        } else {
                            // Sonst: Verlaufseinträge anzeigen (falls vorhanden)
                            if !viewModel.searchHistory.isEmpty {
                                Section("Zuletzt gesucht") {
                                    ForEach(viewModel.searchHistory.prefix(5), id: \.self) { term in
                                        Button(action: {
                                            viewModel.searchText = term
                                            viewModel.updateQuery(term)
                                        }) {
                                            Text(term)
                                        }
                                        .searchCompletion(term)
                                    }
                                    Button("Verlauf löschen", role: .destructive) {
                                        viewModel.clearSearchHistory()
                                    }
                                }
                            }
                        }
                    }
                    .onSubmit(of: .search) {
                        viewModel.commitSearchTerm()
                    }
                    .onChange(of: viewModel.searchText, initial: false) { _, newValue in
                        viewModel.updateQuery(newValue)
                    }
                    // Pull-to-Refresh: manuelles Neuladen der aktuellen Playlist
                    .refreshable {
                        await viewModel.loadVideos(forceReload: true)
                    }
                    // Lädt initial und nur erneut, wenn sich die Playlist-ID ändert
                    .task(id: playlistID) {
                        isPlaylistFavorite = FavoritesManager.shared.isPlaylistFavorite(id: playlistID, context: context)
                        await viewModel.loadVideos()
                    }
                    .alert(isPresented: errorAlertBinding) {
                        Alert(
                            title: Text("Fehler"),
                            message: Text(viewModel.errorMessage ?? "Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es später erneut."),
                            dismissButton: .default(Text("OK"), action: { viewModel.errorMessage = nil })
                        )
                    }
                    .overlay(
                        Group {
                            if let message = viewModel.offlineMessage {
                                Text(message)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                        }, alignment: .top
                    )
                    .overlay {
                        if !viewModel.searchText.isEmpty && viewModel.filteredVideos.isEmpty {
                            ContentUnavailableView(
                                "Keine Treffer",
                                systemImage: "magnifyingglass",
                                description: Text("Bitte Begriff anpassen.")
                            )
                        }
                    }
                    .overlay {
                        if viewModel.showFavoritesOnly && viewModel.filteredVideos.isEmpty {
                            ContentUnavailableView(
                                "Keine Video-Favoriten",
                                systemImage: "heart",
                                description: Text("Tippe das Herz in der Video-Detailansicht, um Videos zu speichern.")
                            )
                        }
                    }
                    .animation(.default, value: viewModel.filteredVideos)
            }
        }
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let container = try! ModelContainer(for: FavoriteVideoEntity.self, FavoriteMentorEntity.self)
            VideoListView(playlistID: ConfigManager.recommendedPlaylistId, context: container.mainContext)
        }
    }
}
