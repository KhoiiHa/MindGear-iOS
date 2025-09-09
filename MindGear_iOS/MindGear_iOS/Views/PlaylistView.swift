//
//  PlaylistView.swift
//  MindGear_iOS
//
//  Zweck: Anzeige einer Playlist mit Suche, Favoriten‑Toggle & Pull‑to‑Refresh.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Listendarstellung, Suchfeld (lokal, debounced via ViewModel), Navigation, Toolbar‑Action.
//  Warum? Schlanke UI; Datenbeschaffung/Paging/Filter liegen im VideoViewModel.
//  Testbarkeit: Klare Accessibility‑IDs; Preview mit In‑Memory ModelContext.
//  Status: stabil.
//

import SwiftUI
import SwiftData
// Kurzzusammenfassung: Filterbare Liste (debounced), Toolbar‑Herz für Playlist‑Favorit, Refresh triggert API‑Reload.

// Local fallback EmptyState for this file (used when global component isn't available)
private struct EmptyState: View {
    let systemImage: String
    let title: String
    let actionTitle: String
    var action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textSecondary(for: scheme))
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textPrimary(for: scheme))
            Button(actionTitle, action: action)
                .buttonStyle(PillButtonStyle())
        }
        .padding(AppTheme.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - PlaylistView
// Warum: Präsentiert Playlist‑Videos; ViewModel kapselt Laden/Suche/Paging.
struct PlaylistView: View {
    @StateObject private var viewModel: VideoViewModel
    @StateObject private var favoritesViewModel: PlaylistFavoritesViewModel
    @State private var firstLoad: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    private let playlistId: String
    private let context: ModelContext

    init(playlistId: String, context: ModelContext) {
        self.playlistId = playlistId
        self.context = context
        _viewModel = StateObject(wrappedValue: VideoViewModel(playlistId: playlistId, context: context))
        _favoritesViewModel = StateObject(wrappedValue: PlaylistFavoritesViewModel(context: context))
    }
    
    private var title: String {
        let t = viewModel.playlistTitle
        return t.isEmpty ? NSLocalizedString("playlist.title.fallback", comment: "") : t
    }
    
    // Bidirektionales Binding zum ViewModel-Suchtext
    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { newValue in viewModel.updateSearch(text: newValue) }
        )
    }
    
    // Vorschläge lokal aus sichtbaren Titeln (Prefix zuerst), max. 6 – kein API‑Call nötig
    private var suggestionItems: [String] {
        let q = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = q.lowercased()
        guard query.count >= 2 else { return [] }
    
        let titles = viewModel.filteredVideos.map { $0.title }
        let prefix = titles.filter { $0.lowercased().hasPrefix(query) }
        let rest = titles.filter { $0.lowercased().contains(query) && !$0.lowercased().hasPrefix(query) }
        var merged: [String] = []
        for t in (prefix + rest) where !merged.contains(t) {
            merged.append(t)
        }
        return Array(merged.prefix(6))
    }

    // MARK: - Subviews (Header)
    // Schlankes Suchfeld – Debounce steckt im ViewModel (Warum: schnelle UX ohne API‑Kosten)
    private var headerSearch: some View {
        SearchField(
            text: searchTextBinding,
            placeholder: NSLocalizedString("search.inPlaylist", comment: ""),
            suggestions: suggestionItems,
            onSubmit: { viewModel.commitSearchTerm() },
            onTapSuggestion: { s in
                viewModel.updateSearch(text: s)
                viewModel.commitSearchTerm()
            },
            accessibilityIdentifier: "playlistSearchField"
        )
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.s)
        .accessibilityLabel(NSLocalizedString("search.title", comment: ""))
        .accessibilityHint(NSLocalizedString("search.inPlaylist.hint", comment: ""))
        .accessibilityAddTraits(.isSearchField)
    }

    // MARK: - Body
    var body: some View {
        List(viewModel.filteredVideos) { video in
            NavigationLink(destination: VideoDetailView(video: video, context: context)) {
                VideoRow(video: video)
            }
            .accessibilityIdentifier("playlistCell_\(video.id)")
        }
        .accessibilityIdentifier("playlistList")
        .refreshable {
            // Force‑Reload → überspringt Session‑Guard und lädt frische Daten
            await viewModel.loadVideos(forceReload: true)
        }
        .tint(AppTheme.Colors.accent)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .listRowSeparator(.hidden)
        .overlay(alignment: .center) {
            if firstLoad && viewModel.filteredVideos.isEmpty {
                // Erstes Laden – ein Spinner + Label (kein doppelter Indicator)
                HStack(spacing: 12) {
                    ProgressView()
                    Text(NSLocalizedString("loading.videos", comment: ""))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }
                .padding()
            } else if viewModel.filteredVideos.isEmpty {
                // Leerzustand mit eigener EmptyState-Komponente
                EmptyState(
                    systemImage: "video.slash",
                    title: NSLocalizedString("playlist.empty.title", comment: ""),
                    actionTitle: NSLocalizedString("action.refresh", comment: "")
                ) {
                    Task { await viewModel.loadVideos(forceReload: true) }
                }
                .padding()
            }
        }
        .task {
            // Initial‑Load: Remote‑Cache → API‑Fallback; Favoritenstatus laden
            await viewModel.loadVideos()
            favoritesViewModel.reload()
            firstLoad = false
        }
        .safeAreaInset(edge: .top) {
            // Warum: Suchfeld bleibt an die Navigation „angedockt“ (klare Hierarchie)
            headerSearch
                .padding(.bottom, 8)
                .background(.thinMaterial)
                .overlay(Divider(), alignment: .bottom)
        }
        .safeAreaInset(edge: .top) {
            if let msg = (viewModel.errorMessage ?? favoritesViewModel.errorMessage), !msg.isEmpty {
                ErrorBanner(message: msg) {
                    viewModel.errorMessage = nil
                    favoritesViewModel.errorMessage = nil
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.bottom, 8)
                .background(AppTheme.listBackground(for: colorScheme))
                .overlay(Rectangle().fill(AppTheme.Colors.separator).frame(height: 1), alignment: .bottom)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(title)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: viewModel.errorMessage)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: favoritesViewModel.errorMessage)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            // Favoriten‑Toggle der Playlist in der Toolbar (gut auffindbar)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { @MainActor in
                        await favoritesViewModel.toggleFavorite(
                            id: playlistId,
                            title: viewModel.playlistTitle.isEmpty ? "Playlist" : viewModel.playlistTitle,
                            thumbnailURL: viewModel.playlistThumbnailURL
                        )
                    }
                } label: {
                    Image(systemName: favoritesViewModel.isFavorite(id: playlistId) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(favoritesViewModel.isFavorite(id: playlistId) ? AppTheme.Colors.accent : AppTheme.Colors.iconSecondary)
                        .symbolEffect(.bounce, value: favoritesViewModel.isFavorite(id: playlistId))
                        .accessibilityLabel(
                            favoritesViewModel.isFavorite(id: playlistId)
                            ? NSLocalizedString("a11y.favorites.remove.playlist", comment: "")
                            : NSLocalizedString("a11y.favorites.add.playlist", comment: "")
                        )
                        .accessibilityHint(NSLocalizedString("a11y.favorites.toggle.playlist", comment: ""))
                }
                .accessibilityIdentifier("favoriteButton")
            }
        }
    }
}

#Preview {
    // In‑Memory Container für eine isolierte Preview
    let container = try! ModelContainer(
        for: WatchHistoryEntity.self,
            FavoritePlaylistEntity.self,
            FavoriteVideoEntity.self,
            FavoriteMentorEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        PlaylistView(playlistId: "PL_PREVIEW_123", context: container.mainContext)
    }
}
