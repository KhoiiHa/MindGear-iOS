import SwiftUI
import SwiftData

struct VideoListView: View {
    let playlistID: String // Playlist-ID für Debugging speichern
    private let context: ModelContext
    @StateObject private var viewModel: VideoViewModel
    @State private var isPlaylistFavorite: Bool = false
    @StateObject private var network = NetworkMonitor.shared
    @State private var selectedChip: String? = nil
    private let exploreChips: [String] = [
        "Mindset",
        "Disziplin & Fokus",
        "Emotionale Intelligenz",
        "Beziehungen",
        "Innere Ruhe & Achtsamkeit",
        "Motivation & Energie"
    ]
    @Environment(\.colorScheme) private var colorScheme

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

    // Schlankes, wiederverwendbares Suchfeld – Debounce steckt im ViewModel
    private var headerSearch: some View {
        TextField(
            "In Playlist suchen",
            text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.updateSearch(text: $0) }
            )
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .submitLabel(.search)
        .onSubmit { viewModel.commitSearchTerm() }
        .accessibilityIdentifier("playlistSearchField")
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.s)
        .textFieldStyle(.roundedBorder)
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
                    VideoRow(video: video)
                }
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("videoCell_\(video.id)")
                .onAppear {
                    // Infinite Scroll entfernt - kein Nachladen mehr hier
                }
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .listRowSeparator(.hidden)
        .listRowSeparatorTint(AppTheme.Colors.separator)
        .background(AppTheme.listBackground(for: colorScheme))
        .accessibilityIdentifier("videosList")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🔎 Sichtbares Suchfeld für UI-Tests (playlistSearchField)
                headerSearch
                videosList
            }
            .navigationTitle("Videos")
            .toolbarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Toggle(isOn: favoritesOnlyBinding) {
                        Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.showFavoritesOnly ? AppTheme.Colors.accent : AppTheme.Colors.iconSecondary)
                    }
                    .toggleStyle(.button)
                    .accessibilityIdentifier("favoritesOnlyToggle")
                    .accessibilityLabel("Nur Favoriten anzeigen")
                    .accessibilityHint("Nur gespeicherte Videos ein- oder ausblenden.")

                    Button { togglePlaylistFavorite() } label: {
                        Image(systemName: isPlaylistFavorite ? "star.fill" : "star")
                            .foregroundStyle(isPlaylistFavorite ? AppTheme.Colors.highlight : AppTheme.Colors.iconSecondary)
                    }
                    .accessibilityLabel(isPlaylistFavorite ? "Playlist aus Favoriten entfernen" : "Playlist zu Favoriten hinzufügen")
                    .accessibilityIdentifier("playlistFavoriteButton")
                    .accessibilityHint("Favoritenstatus der Playlist ändern.")
                }
            }
            // Pull-to-Refresh: manuelles Neuladen der aktuellen Playlist
            .refreshable { await viewModel.loadVideos(forceReload: true) }
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.immediately)
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
                        description: Text("Begriff anpassen oder Verlauf nutzen.")
                    )
                }
            }
            .overlay {
                if viewModel.showFavoritesOnly && viewModel.filteredVideos.isEmpty {
                    ContentUnavailableView(
                        "Keine Video-Favoriten",
                        systemImage: "heart.fill",
                        description: Text("Speichere Videos mit dem Herz in der Detailansicht.")
                    )
                }
            }
            .animation(.default, value: viewModel.filteredVideos)
        }
    }
}

private struct ChipView: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.footnote)
                .lineLimit(1)
                .padding(.vertical, AppTheme.Spacing.xs)
                .padding(.horizontal, AppTheme.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                        .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                        .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
                )
                .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .shadow(color: AppTheme.Colors.shadowCard.opacity(isSelected ? 0.6 : 0.3), radius: isSelected ? 6 : 4, y: isSelected ? 3 : 2)
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
