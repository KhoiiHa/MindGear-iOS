//
//  CategoryDetailView.swift
//  MindGear_iOS
//
//  Zweck: Detailseite einer Kategorie mit Playlist‑Vorschauen & lokalem Suchfeld.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Header‑Suche, Vorschau‑Sektionen, Navigation zu Video/Playlist.
//  Warum? Schlanke UI; Datenbeschaffung & Logik liegen in ViewModels/Services.
//  Testbarkeit: Previews & klare Accessibility‑Labels/IDs.
//  Status: stabil.
//

import SwiftUI
import SwiftData
// Kurzzusammenfassung: Oben Suchfeld, darunter 1–2 Playlist‑Previews (Empfohlen/Neu) mit Navigation.

// MARK: - CategoryDetailView
// Warum: Präsentiert kuratierten Inhalt pro Kategorie; bindet Playlist‑Previews ein.
struct CategoryDetailView: View {
    let category: Category
    let modelContext: ModelContext
    // Programmgesteuerte Navigation zum Video-Detail
    @State private var selectedVideo: Video? = nil
    @State private var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Subviews (Header)
    // Schlankes Suchfeld (lokal) – Filter greift in den Preview‑Sektionen
    private var headerSearch: some View {
        SearchField(
            text: $searchText,
            suggestions: [],
            accessibilityHintKey: "search.generic.hint",
            onSubmit: {},
            onTapSuggestion: { q in searchText = q },
            accessibilityIdentifier: "categorySearch"
        )
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.s)
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.l) {
                Text(category.icon)
                    .font(.system(size: 72))
                    .accessibilityHidden(true)
                Text(category.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                Text("Hier findest du passende Playlists und Impulse für die Kategorie \"\(category.name)\". (Beschreibung kann später angepasst werden)")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .padding(.bottom, AppTheme.Spacing.m)

                Rectangle()
                    .fill(AppTheme.Colors.separator)
                    .frame(height: 1)

                Group {
                    if let recommendedId = playlistIDs.recommended {
                        PlaylistPreviewSection(
                            title: "Empfohlen",
                            playlistId: recommendedId,
                            categoryName: category.name,
                            filterText: searchText,
                            context: modelContext,
                            onSelect: { video in selectedVideo = video }
                        )
                    }
                    if let recentId = playlistIDs.recent {
                        PlaylistPreviewSection(
                            title: "Neu",
                            playlistId: recentId,
                            categoryName: category.name,
                            filterText: searchText,
                            context: modelContext,
                            onSelect: { video in selectedVideo = video }
                        )
                    }
                    if playlistIDs.recommended == nil && playlistIDs.recent == nil {
                        Text("📦 Noch keine Playlist verknüpft.")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .padding(.top, AppTheme.Spacing.l)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, AppTheme.Spacing.m)
        }
        .background(AppTheme.listBackground(for: colorScheme))
        .scrollIndicators(.hidden)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            // Warum: Suchfeld bleibt visuell an die Navigation gekoppelt
            headerSearch
                .background(AppTheme.listBackground(for: colorScheme))
        }
        .navigationDestination(item: $selectedVideo) { video in
            VideoDetailView(video: video, context: modelContext)
        }
    }

    // MARK: - Helpers
    // Liefert die empfohlenen und neuen Playlist‑IDs für die aktuelle Kategorie
    private var playlistIDs: (recommended: String?, recent: String?) {
        // Hinweis: Mapping ist bewusst simpel; kann später über Config/Remote ersetzt werden
        switch category.name {
        case "Mindset":
            return (ConfigManager.recommendedPlaylistId, ConfigManager.recommendedPlaylistId)
        case "Disziplin & Fokus":
            return (ConfigManager.shawnRyanPlaylistId, ConfigManager.shawnRyanPlaylistId)
        case "Emotionale Intelligenz":
            return (ConfigManager.jayShettyPlaylistId, ConfigManager.jayShettyPlaylistId)
        case "Beziehungen":
            return (ConfigManager.simonSinekPlaylistId, ConfigManager.simonSinekPlaylistId)
        case "Innere Ruhe & Achtsamkeit":
            return (ConfigManager.shiHengYiPlaylistId, ConfigManager.shiHengYiPlaylistId)
        case "Motivation & Energie":
            return (ConfigManager.diaryOfACeoPlaylistId, ConfigManager.diaryOfACeoPlaylistId)
        case "Werte & Purpose":
            return (ConfigManager.jordanBPetersonPlaylistId, ConfigManager.jordanBPetersonPlaylistId)
        case "Impulse & Perspektiven":
            return (ConfigManager.theoVonPlaylistId, ConfigManager.theoVonPlaylistId)
        default:
            return (nil, nil)
        }
    }
}


// MARK: - PlaylistPreviewSection
// Warum: Wiederverwendbare, horizontale Vorschau einer Playlist (5er‑Teaser)
struct PlaylistPreviewSection: View {
    let title: String
    let playlistId: String
    let categoryName: String
    let filterText: String
    let context: ModelContext
    let onSelect: (Video) -> Void

    // Ladezustand & Daten für die Vorschau (z. B. 5 Items)
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var videos: [Video] = []
    @State private var hasLoaded = false
    @Environment(\.colorScheme) private var colorScheme

    // Gefilterte Videos (Filter aus dem ViewBuilder herausgezogen)
    private var filteredVideos: [Video] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return videos }
        return videos.filter { v in
            v.title.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
            v.description.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    // MARK: - Body
    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                SectionHeader(title: LocalizedStringKey(title))
                NavigationLink(destination: PlaylistView(playlistId: playlistId, context: context)) {
                    Text("section.seeAll")
                        .font(.subheadline)
                }
                .disabled(isLoading)
                .accessibilityLabel("Alle Videos in \(title) anzeigen")
                .accessibilityHint("Öffnet die Playlist.")

                if isLoading {
                    // Skeleton-Placeholders während des Ladens
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: AppTheme.Spacing.m) {
                            ForEach(0..<5, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                                    .fill(AppTheme.Colors.surfaceElevated)
                                    .frame(width: 160, height: 96)
                                    .accessibilityHidden(true)
                                    .redacted(reason: .placeholder)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                    .accessibilityHidden(true)
                } else if let errorMessage = errorMessage {
                    // Fehlerzustand mit Retry
                    HStack(spacing: AppTheme.Spacing.m) {
                        Image(systemName: "exclamationmark.triangle")
                            .accessibilityHidden(true)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        Spacer()
                        Button("Erneut laden") {
                            Task { await loadPreview() }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Erneut laden")
                        .accessibilityHint("Lädt die Vorschau erneut.")
                        .tint(AppTheme.Colors.accent)
                    }
                    .padding(.vertical, 8)
                } else if videos.isEmpty {
                    // Empty-State
                    Text("Keine Inhalte gefunden.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .padding(.vertical, AppTheme.Spacing.xs)
                } else {
                    // Erfolgszustand: horizontale Vorschau – gefiltert nach Suchtext
                    let visible = filteredVideos

                    if visible.isEmpty {
                        Text("Keine Inhalte gefunden.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .padding(.vertical, AppTheme.Spacing.xs)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: AppTheme.Spacing.m) {
                                ForEach(visible, id: \.id) { video in
                                    Button(action: { onSelect(video) }) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            ThumbnailView(urlString: video.thumbnailURL)
                                                .frame(width: 160, height: 96)
                                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous))
                                                .accessibilityHidden(true)

                                            Text(video.title)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                                                .lineLimit(2)
                                                .frame(width: 160, alignment: .leading)
                                        }
                                        .contentShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous))
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel(video.title)
                                        .accessibilityValue("Video")
                                        .accessibilityHint("Doppeltippen, um Details zu öffnen.")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, AppTheme.Spacing.xs)
                        }
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)
            .task {
                // Startet das Laden beim ersten Erscheinen der Sektion
                if !hasLoaded { await loadPreview() }
            }
        }
    }

    /// Lädt eine kleine Vorschau (bis zu `limit` Items) für die Playlist und mappt auf `Video`.
    /// Warum: Schneller Teaser in der Kategorie; vollständige Liste steckt in `PlaylistView`.
    @MainActor
    func loadPreview(limit: Int = 5) async {
        if hasLoaded { return }
        isLoading = true
        errorMessage = nil
        guard !ConfigManager.youtubeAPIKey.isEmpty else {
            self.errorMessage = "API-Schlüssel fehlt."
            self.isLoading = false
            return
        }
        do {
            // Datenquelle: Direkter API‑Call (hier keine Remote‑Cache‑Nutzung, da nur Teaser)
            // API-Aufruf: nutzt den stabilisierten APIService
            let response = try await APIService.shared.fetchVideos(from: playlistId, apiKey: ConfigManager.youtubeAPIKey, pageToken: nil)
            // Map auf Domain-Model (robuster Mapper mit Fallbacks)
            let mapped = response.items.compactMap { $0.toVideo(category: categoryName) }
            self.videos = Array(mapped.prefix(limit))
            self.hasLoaded = true
            self.isLoading = false
        } catch {
            // Nutzerfreundliche Fehlermeldung, Log in der Konsole für Diagnose
            print("[CategoryPreview] load error:", error.localizedDescription)
            self.errorMessage = "Inhalte konnten nicht geladen werden."
            self.isLoading = false
        }
    }
}
