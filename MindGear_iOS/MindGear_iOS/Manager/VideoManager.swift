/// Zweck: Leichter Facade/Helper, um den APIService zu kapseln und Sample-Daten bereitzustellen.
/// Diese Klasse vereinfacht den Zugriff auf YouTube-Playlist-Videos und stellt Beispielvideos bereit.
import Foundation

// Liefert Beispielvideos und kapselt API-Aufrufe
final class VideoManager {
    static let shared = VideoManager()

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
    /// Lädt die erste Seite einer Playlist
    func fetchFirstPage(
        playlistId: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeResponse {
        try await api.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt die erste Seite einer YouTube-Suche
    func fetchFirstSearchPage(
        query: String,
        apiKey: String,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> YouTubeSearchResponse {
        try await api.searchVideos(query: query, apiKey: apiKey, pageToken: nil)
    }

    /// Lädt eine Vorschau-Liste für eine Playlist
    func fetchPlaylistPreview(
        playlistId: String,
        category: String,
        limit: Int = 5,
        api: APIServiceProtocol = APIService.shared
    ) async throws -> [Video] {
        let response = try await api.fetchVideos(from: playlistId, apiKey: ConfigManager.youtubeAPIKey, pageToken: nil)
        return response.items.prefix(limit).compactMap { $0.toVideo(category: category) }
    }

    // MARK: - Helpers
    /// Sucht Video per UUID in einer Liste
    func getVideo(by id: UUID, in list: [Video]) -> Video? {
        list.first { $0.id == id }
    }

    /// Variante für String-ID (z. B. Favoriten)
    func getVideo(by idString: String, in list: [Video]) -> Video? {
        guard let uuid = UUID(uuidString: idString) else { return nil }
        return getVideo(by: uuid, in: list)
    }
}
