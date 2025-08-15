import SwiftUI
import SwiftData

struct VideoListView: View {
    let playlistID: String // Playlist-ID für Debugging speichern
    private let context: ModelContext
    @StateObject private var viewModel: VideoViewModel
    @State private var isPlaylistFavorite: Bool = false
    @StateObject private var network = NetworkMonitor.shared

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
            set: { viewModel.updateSearch(text: $0) }
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

    // Schlankes, wiederverwendbares Suchfeld – Debounce steckt im ViewModel
    private var headerSearch: some View {
        SearchField(
            text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.updateSearch(text: $0) }
            ),
            suggestions: Array(viewModel.searchHistory.prefix(5)),
            onSubmit: { viewModel.commitSearchTerm() },
            onTapSuggestion: { q in
                viewModel.updateSearch(text: q)
                viewModel.commitSearchTerm()
            }
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityLabel("Suche")
        .accessibilityHint("Eingeben, um Ergebnisse zu filtern.")
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
                        .accessibilityLabel(isPlaylistFavorite ? "Playlist aus Favoriten entfernen" : "Playlist zu Favoriten hinzufügen")
                        .accessibilityHint("Favoritenstatus der Playlist ändern.")
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
                            .accessibilityHint("Nur gespeicherte Videos ein- oder ausblenden.")

                            Button {
                                togglePlaylistFavorite()
                            } label: {
                                Image(systemName: isPlaylistFavorite ? "star.fill" : "star")
                                    .foregroundColor(isPlaylistFavorite ? .yellow : .gray)
                            }
                            .accessibilityLabel(isPlaylistFavorite ? "Playlist aus Favoriten entfernen" : "Playlist zu Favoriten hinzufügen")
                            .accessibilityHint("Favoritenstatus der Playlist ändern.")
                        }
                    }
                    // Removed searchable-related modifiers

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
                    .safeAreaInset(edge: .top) {
                        VStack(spacing: 8) {
                            // Suchfeld immer sichtbar oberhalb der Liste
                            headerSearch

                            // Offline-Banner nur bei fehlender Verbindung
                            if network.isOffline {
                                HStack(spacing: 12) {
                                    Image(systemName: "wifi.exclamationmark")
                                    Text("Offline: Zeige gespeicherte Inhalte")
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Erneut versuchen") {
                                        Task {
                                            APIService.clearCache()
                                            await viewModel.loadVideos(forceReload: true)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(network.isOffline)
                                }
                                .font(.footnote)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color.yellow.opacity(0.15))
                                .overlay(Divider(), alignment: .bottom)
                            }
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
