/// Zweck: Leichter Facade/Helper, um den APIService zu kapseln und Sample-Daten bereitzustellen.
/// Diese Klasse vereinfacht den Zugriff auf YouTube-Playlist-Videos und stellt Beispielvideos bereit.
import Foundation

final class VideoManager {
    static let shared = VideoManager()

    private init() {}

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

    /// Lädt die erste Seite einer Playlist (ohne pageToken) über den gegebenen API-Service.
    /// Gibt die vollständige YouTubeResponse zurück, inkl. nextPageToken für Pagination.
    func fetchFirstPage(
        playlistId: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeResponse {
        try await api.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt die nächste Seite einer Playlist anhand des übergebenen pageToken.
    /// Reicht direkt an den API-Service durch und liefert die vollständige YouTubeResponse.
    func fetchNextPage(
        playlistId: String,
        apiKey: String,
        pageToken: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeResponse {
        try await api.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: pageToken)
    }
    /// Lädt eine kleine Vorschau-Liste (z. B. 5 Items) für eine Playlist und mappt sie auf `Video`.
    /// - Parameters:
    ///   - playlistId: Die YouTube-Playlist-ID
    ///   - category: Name der App-Kategorie (wird im Mapper für `toVideo(category:)` genutzt)
    ///   - limit: Anzahl der gewünschten Items (Default: 5)
    ///   - api: API-Service (standardmäßig `APIService.shared`)
    /// - Returns: Gemappte `Video`-Objekte, auf `limit` gekürzt
    func fetchPlaylistPreview(
        playlistId: String,
        category: String,
        limit: Int = 5,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> [Video] {
        let response = try await api.fetchVideos(from: playlistId, apiKey: ConfigManager.apiKey, pageToken: nil)
        let mapped = response.items.compactMap { $0.toVideo(category: category) }
        return Array(mapped.prefix(limit))
    }
}
