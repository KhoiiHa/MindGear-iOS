import SwiftUI
import SwiftData

struct VideoListView: View {
    let playlistID: String // Playlist-ID für Debugging speichern
    private let context: ModelContext
    @StateObject private var viewModel: VideoViewModel

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

    // Ausgelagerte Liste zur Entlastung der Typinferenz
    private var videosList: some View {
        List {
            ForEach(viewModel.filteredVideos) { (video: Video) in
                NavigationLink(destination: VideoDetailView(video: video, context: context)) {
                    VideoRow(video: video)
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
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Toggle(isOn: favoritesOnlyBinding) {
                                Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                                    .foregroundColor(viewModel.showFavoritesOnly ? .red : .gray)
                            }
                            .toggleStyle(.button)
                            .accessibilityLabel("Nur Favoriten anzeigen")
                        }
                    }
                    .searchable(text: searchTextBinding, prompt: "Suche Videos")
                    // Pull-to-Refresh: manuelles Neuladen der aktuellen Playlist
                    .refreshable {
                        await viewModel.loadVideos(forceReload: true)
                    }
                    // Lädt initial und nur erneut, wenn sich die Playlist-ID ändert
                    .task(id: playlistID) {
                        await viewModel.loadVideos()
                    }
                    .alert(isPresented: errorAlertBinding) {
                        Alert(
                            title: Text("Fehler"),
                            message: Text(viewModel.errorMessage ?? "Ein unbekannter Fehler ist aufgetreten."),
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
                
#if DEBUG
                // DebugBadge zeigt im Debug-Build die aktuelle Playlist-ID an
                Text("PlaylistID: \(playlistID)")
                    .font(.caption2)
                    .padding(6)
                    .background(Color.yellow.opacity(0.8))
                    .cornerRadius(8)
                    .padding()
#endif
            }
        }
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let container = try! ModelContainer(for: FavoriteVideoEntity.self)
            VideoListView(playlistID: ConfigManager.recommendedPlaylistId, context: container.mainContext)
        }
    }
}
