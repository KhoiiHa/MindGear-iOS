//
//  VideoManager.swift
//  MindGear_iOS
//
//  Zweck: Leichte Fassade um APIService + Sample-Daten für UI/Previews.
//  Architekturrolle: Service/Manager (domänennah; keine Networking-Details).
//  Verantwortung: Erstseiten-Fetch (Playlist/Suche), Playlist-Vorschau, Sample-Videos, Lookups.
//  Warum? Entlastet ViewModels; bündelt wiederkehrende Video-Logik & hält Abhängigkeiten injizierbar.
//  Testbarkeit: API via `APIServiceProtocol` injizierbar; reine Helper sind pure functions.
//  Status: stabil.
//
import Foundation

// Kurzzusammenfassung: Einfache API-Fassade + Beispielinhalte für Previews & Offline-Demos.

// MARK: - Implementierung: VideoManager
final class VideoManager {
    static let shared = VideoManager()

    // MARK: - Init
    private init() {}

    // MARK: - Sample Data
    func getSampleVideos() -> [Video] {
        return [
            Video(
                id: UUID(),
                title: "Die Kraft der Achtsamkeit",
                description: "Ein inspirierendes Video über Achtsamkeit im Alltag.",
                thumbnailURL: "https://example.com/thumbnail1.jpg",
                videoURL: "https://youtube.com/watch?v=xyz",
                category: "Achtsamkeit"
            ),
            Video(
                id: UUID(),
                title: "Mentale Stärke entwickeln",
                description: "Tipps und Übungen für mehr mentale Widerstandskraft.",
                thumbnailURL: "https://example.com/thumbnail2.jpg",
                videoURL: "https://youtube.com/watch?v=abc",
                category: "Motivation"
            )
        ]
    }

    // MARK: - API
    /// Lädt die erste Seite einer Playlist.
    /// Warum: UI braucht einen einfachen Einstieg (ohne Paging/Token-Handling) – Paging folgt später am Call‑Site.
    func fetchFirstPage(
        playlistId: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeResponse {
        try await api.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt die erste Seite einer YouTube-Suche.
    /// Warum: Gleiche Idee wie bei Playlist – bewusste Vereinfachung für erste Ergebnisse.
    func fetchFirstSearchPage(
        query: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeSearchResponse {
        try await api.searchVideos(query: query, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt eine Vorschau-Liste für eine Playlist.
    /// Warum: Schnelle UI-Teaser (Home/Sections); begrenzt via `limit` und mappt direkt aufs Domänenmodell.
    func fetchPlaylistPreview(
        playlistId: String,
        category: String,
        limit: Int = 5,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> [Video] {
        let response = try await api.fetchVideos(from: playlistId, apiKey: ConfigManager.youtubeAPIKey, pageToken: nil)
        // Direktes Mapping ins App-Modell vermeidet ViewModel-Wissen über API-Schema.
        return response.items.prefix(limit).compactMap { $0.toVideo(category: category) }
    }

    // MARK: - Helpers
    /// Sucht ein Video per UUID in einer Liste.
    /// Warum: Häufige Lookup-Operation für Detail-Navigation.
    func getVideo(by id: UUID, in list: [Video]) -> Video? {
        list.first { $0.id == id }
    }

    /// Variante für String-ID (z. B. Favoriten-Speicher).
    /// Warum: Erlaubt flexible Quellen; validiert/konvertiert defensiv nach UUID.
    func getVideo(by idString: String, in list: [Video]) -> Video? {
        guard let uuid = UUID(uuidString: idString) else { return nil }
        return getVideo(by: uuid, in: list)
    }
}
