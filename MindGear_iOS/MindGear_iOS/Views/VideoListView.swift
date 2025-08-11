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

    // Hilfsfunktion: Ist dieses Video das letzte (für Pagination-Trigger)?
    private func isLast(_ video: Video) -> Bool {
        video == viewModel.filteredVideos.last
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
                    if isLast(video) {
                        Task { await viewModel.loadMoreVideos() }
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView("Mehr laden…")
                        .padding(.vertical, 12)
                    Spacer()
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
