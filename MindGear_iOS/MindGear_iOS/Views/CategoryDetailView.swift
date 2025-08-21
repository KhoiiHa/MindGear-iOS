//
//  CategoryDetailView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 06.08.25.
//

import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: Category
    let modelContext: ModelContext
    // Programmgesteuerte Navigation zum Video-Detail
    @State private var selectedVideo: Video? = nil
    @State private var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme

    // Schlankes Suchfeld als Header – Filter passiert in den Vorschau‑Sektionen
    private var headerSearch: some View {
        SearchField(
            text: $searchText,
            suggestions: [], // optional: Kategorien‑bezogene Vorschläge
            onSubmit: {},
            onTapSuggestion: { q in searchText = q }
        )
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.s)
        .accessibilityLabel("Suche")
        .accessibilityHint("Eingeben, um Inhalte in dieser Kategorie zu filtern.")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.l) {
                Text(category.icon)
                    .font(.system(size: 72))
                    .accessibilityHidden(true)
                Text(category.name)
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .accessibilityHeading(.h1)
                Text("Hier findest du passende Playlists und Impulse für die Kategorie \"\(category.name)\". (Beschreibung kann später angepasst werden)")
                    .font(AppTheme.Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
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
        .background(AppTheme.Colors.background)
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.tabBarBackground(for: colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            headerSearch
                .background(AppTheme.listBackground(for: colorScheme))
        }
        .navigationDestination(item: $selectedVideo) { video in
            VideoDetailView(video: video, context: modelContext)
        }
    }

    // Liefert die empfohlenen und neuen Playlist-IDs für die aktuelle Kategorie
    private var playlistIDs: (recommended: String?, recent: String?) {
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


// PlaylistPreviewSection: Zeigt einen horizontalen Bereich mit Video-Thumbnails einer Playlist und "Alle anzeigen"-Button
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

    // Gefilterte Videos (Filter aus dem ViewBuilder herausgezogen)
    private var filteredVideos: [Video] {
        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return videos }
        return videos.filter { v in
            v.title.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil ||
            v.description.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack(spacing: AppTheme.Spacing.m) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .accessibilityHeading(.h2)
                    Spacer()
                    NavigationLink(destination: PlaylistView(playlistId: playlistId, context: context)) {
                        Text("Alle anzeigen")
                            .font(AppTheme.Typography.subheadline)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Alle Videos in \(title) anzeigen")
                    .accessibilityHint("Öffnet die Playlist.")
                }

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
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
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
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.vertical, AppTheme.Spacing.xs)
                } else {
                    // Erfolgszustand: horizontale Vorschau – gefiltert nach Suchtext
                    let visible = filteredVideos

                    if visible.isEmpty {
                        Text("Keine Inhalte gefunden.")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
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
                                                .font(AppTheme.Typography.caption)
                                                .foregroundStyle(AppTheme.Colors.textPrimary)
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

    // Lädt die ersten Videos einer Playlist über den APIService und mappt sie auf `Video`
    func loadPreview(limit: Int = 5) async {
        if hasLoaded { return }
        isLoading = true
        errorMessage = nil
        do {
            // API-Aufruf: nutzt den stabilisierten APIService
            let response = try await APIService.shared.fetchVideos(from: playlistId, apiKey: ConfigManager.apiKey, pageToken: nil)
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
