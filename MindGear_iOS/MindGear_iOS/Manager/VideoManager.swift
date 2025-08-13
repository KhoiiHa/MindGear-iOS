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

    /// Lädt die erste Seite einer Playlist.
    func fetchFirstPage(
        playlistId: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeResponse {
        try await api.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt die erste Seite einer YouTube-Suche.
    func fetchFirstSearchPage(
        query: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeSearchResponse {
        try await api.searchVideos(query: query, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt eine Vorschau-Liste für eine Playlist.
    func fetchPlaylistPreview(
        playlistId: String,
        category: String,
        limit: Int = 5,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> [Video] {
        let response = try await api.fetchVideos(from: playlistId, apiKey: ConfigManager.apiKey, pageToken: nil)
        return response.items.prefix(limit).compactMap { $0.toVideo(category: category) }
    }
}
