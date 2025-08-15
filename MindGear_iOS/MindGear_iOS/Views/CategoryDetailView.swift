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

    // Schlankes Suchfeld als Header – Filter passiert in den Vorschau‑Sektionen
    private var headerSearch: some View {
        SearchField(
            text: $searchText,
            suggestions: [], // optional: Kategorien‑bezogene Vorschläge
            onSubmit: {},
            onTapSuggestion: { q in searchText = q }
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .accessibilityLabel("Suche")
        .accessibilityHint("Eingeben, um Inhalte in dieser Kategorie zu filtern.")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(category.icon)
                    .font(.system(size: 72))
                    .accessibilityHidden(true)
                Text(category.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .accessibilityHeading(.h1)
                Text("Hier findest du passende Playlists und Impulse für die Kategorie \"\(category.name)\". (Beschreibung kann später angepasst werden)")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)

                Divider()

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
                            .foregroundColor(.secondary)
                            .padding(.top, 32)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) { headerSearch }
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .bold()
                        .accessibilityHeading(.h2)
                    Spacer()
                    NavigationLink(destination: PlaylistView(playlistId: playlistId, context: context)) {
                        Text("Alle anzeigen")
                            .font(.subheadline)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Alle Videos in \(title) anzeigen")
                    .accessibilityHint("Öffnet die Playlist.")
                }

                if isLoading {
                    // Skeleton-Placeholders während des Ladens
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: 160, height: 96)
                                    .accessibilityHidden(true)
                                    .redacted(reason: .placeholder)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityHidden(true)
                } else if let errorMessage = errorMessage {
                    // Fehlerzustand mit Retry
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .accessibilityHidden(true)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Erneut laden") {
                            Task { await loadPreview() }
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Erneut laden")
                        .accessibilityHint("Lädt die Vorschau erneut.")
                    }
                    .padding(.vertical, 8)
                } else if videos.isEmpty {
                    // Empty-State
                    Text("Keine Inhalte gefunden.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    // Erfolgszustand: horizontale Vorschau – gefiltert nach Suchtext
                    let visible = filteredVideos

                    if visible.isEmpty {
                        Text("Keine Inhalte gefunden.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 16) {
                                ForEach(visible, id: \.id) { video in
                                    Button(action: { onSelect(video) }) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            ThumbnailView(urlString: video.thumbnailURL)
                                                .frame(width: 160, height: 96)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                .accessibilityHidden(true)

                                            Text(video.title)
                                                .font(.caption)
                                                .lineLimit(2)
                                                .frame(width: 160, alignment: .leading)
                                        }
                                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .accessibilityElement(children: .combine)
                                        .accessibilityLabel(video.title)
                                        .accessibilityValue("Video")
                                        .accessibilityHint("Doppeltippen, um Details zu öffnen.")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
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
