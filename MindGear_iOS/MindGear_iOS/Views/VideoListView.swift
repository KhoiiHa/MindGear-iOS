//
//  VideoListView.swift
//  MindGear_iOS
//
//  Zweck: Liste aller Videos einer Playlist mit Suche, Favoriten‑Filter & Pull‑to‑Refresh.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Suchfeld (lokal, Debounce im ViewModel), Listendarstellung, Toolbar‑Filter, Navigation.
//  Warum? Schlanke UI; Datenbeschaffung/Paging/Filter liegen im VideoViewModel/Services.
//  Testbarkeit: Klare Accessibility‑IDs; Previews mit In‑Memory ModelContainer.
//  Status: stabil.
//

import SwiftUI
import SwiftData

// Kurzzusammenfassung: Remote‑Cache → API, debouncte Suche, Favoriten‑Filter, Offline‑Hinweis oben.

// MARK: - VideoListView
// Warum: Präsentiert Playlist‑Videos; ViewModel kapselt Laden/Suche/Paging.
struct VideoListView: View {
    let playlistID: String // Playlist-ID für Debugging speichern
    private let context: ModelContext
    @StateObject private var viewModel: VideoViewModel
    @State private var isPlaylistFavorite: Bool = false
    @ObservedObject private var network = NetworkMonitor.shared
    @State private var selectedChip: String? = nil
    /// Flag für erstes Laden (Spinner/Empty-Handling)
    @State private var firstLoad: Bool = true
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

    // Explizite Bindings entlasten die Dynamik von $viewModel
    private var favoritesOnlyBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showFavoritesOnly },
            set: { viewModel.showFavoritesOnly = $0 }
        )
    }

    // Entkoppelte Referenz auf das StateObject (verhindert Wrapper-Inferenz in Subviews)
    private var vmRef: VideoViewModel { viewModel }

    // Schlankes Suchfeld – Debounce steckt im ViewModel (Warum: schnelle UX ohne API‑Kosten)
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

    // MARK: - Subviews (Liste)
    @ViewBuilder private var videosList: some View {
        Group {
            let isEmpty = vmRef.filteredVideos.isEmpty
            if firstLoad && isEmpty {
                ProgressView {
                    HStack(spacing: 12) {
                        ProgressView()
                            .accessibilityIdentifier("loadingSpinner")
                        Text("Lade Videos…")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(vmRef.filteredVideos) { (video: Video) in
                        NavigationLink(destination: VideoDetailView(video: video, context: context)) {
                            VStack(spacing: 0) {
                                VideoRow(video: video)
                                    .accessibilityIdentifier("videoCellContent_\(video.id)")
                            }
                            .mgCard()
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("videoCell_\(video.id)")
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .scrollContentBackground(.hidden)
                .listRowSeparator(.hidden)
                // Einheitliches Listen‑Styling gemäß AppTheme (auch im Dark Mode)
                .background(AppTheme.listBackground(for: colorScheme))
                .accessibilityIdentifier("videosList")
            }
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🔎 Sichtbares Suchfeld für UI-Tests (playlistSearchField)
                headerSearch
                // 🔔 Einheitlicher Fehlerbanner (nicht-blockierend)
                if let msg = viewModel.errorMessage, !msg.isEmpty {
                    ErrorBanner(message: msg) {
                        viewModel.errorMessage = nil
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, AppTheme.Spacing.s)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: viewModel.errorMessage)
                }
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
            .refreshable {
                // Force‑Reload → überspringt Session‑Guard und lädt frische Daten
                await viewModel.loadVideos(forceReload: true)
            }
            .tint(AppTheme.Colors.accent)
            .scrollDismissesKeyboard(.immediately)
            // Lädt initial und nur erneut, wenn sich die Playlist-ID ändert
            .task(id: playlistID) {
                // Initial‑Load: Remote‑Cache → API‑Fallback; Favoritenstatus laden
                isPlaylistFavorite = FavoritesManager.shared.isPlaylistFavorite(id: playlistID, context: context)
                await viewModel.loadVideos()
                firstLoad = false
            }
            .overlay {
                // Leerzustand bei aktiver Suche – Hinweis, Begriff anzupassen
                if !viewModel.searchText.isEmpty && viewModel.filteredVideos.isEmpty {
                    ContentUnavailableView(
                        "Keine Treffer",
                        systemImage: "magnifyingglass",
                        description: Text("Begriff anpassen oder Verlauf nutzen.")
                    )
                }
            }
            .overlay {
                // Leerzustand bei aktivem Favoriten‑Filter – erklärt den nächsten Schritt
                if viewModel.showFavoritesOnly && viewModel.filteredVideos.isEmpty {
                    ContentUnavailableView(
                        "Keine Video-Favoriten",
                        systemImage: "heart.fill",
                        description: Text("Speichere Videos mit dem Herz in der Detailansicht.")
                    )
                }
            }
            .overlay(alignment: .top) {
                // Offline/Fehler‑Hinweis fixiert oben – unaufdringlich, aber sichtbar
                if let offline = viewModel.offlineMessage, !offline.isEmpty {
                    Text(offline)
                        .font(.caption)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.top, 8)
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
                .font(.footnote)
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
                .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.textSecondary(for: colorScheme))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .shadow(color: AppTheme.Colors.shadowCard.opacity(isSelected ? 0.6 : 0.3), radius: isSelected ? 6 : 4, y: isSelected ? 3 : 2)
    }
}

struct VideoListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let container = try! ModelContainer(
                for: FavoriteVideoEntity.self,
                    FavoriteMentorEntity.self,
                    FavoritePlaylistEntity.self,
                    WatchHistoryEntity.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            VideoListView(playlistID: "PL_PREVIEW_123", context: container.mainContext)
        }

        NavigationStack {
            let container = try! ModelContainer(
                for: FavoriteVideoEntity.self,
                    FavoriteMentorEntity.self,
                    FavoritePlaylistEntity.self,
                    WatchHistoryEntity.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            VideoListView(playlistID: "PL_PREVIEW_123", context: container.mainContext)
        }
        .preferredColorScheme(.dark)
    }
}
