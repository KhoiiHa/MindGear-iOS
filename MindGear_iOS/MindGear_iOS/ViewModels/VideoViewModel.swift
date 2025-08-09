import Foundation
import SwiftData

@MainActor
class VideoViewModel: ObservableObject {
    // Merker: Welche Playlists wurden in dieser App-Session bereits einmal initial geladen?
    private static var loadedOnce = Set<String>()
    @Published var videos: [Video] = []
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var offlineMessage: String? = nil

    // Pagination-Status
    @Published var isLoadingMore: Bool = false
    private var nextPageToken: String? = nil

    // Lädt API-Schlüssel dynamisch aus der Config
    private let apiKey = ConfigManager.apiKey
    private let playlistId: String

    private let apiService: APIServiceProtocol
    private var context: ModelContext

    init(playlistId: String, apiService: APIServiceProtocol = APIService.shared, context: ModelContext) {
        self.playlistId = playlistId
        self.apiService = apiService
        self.context = context
    }

    /// Lädt Videos aus der YouTube-Playlist und aktualisiert die Liste der Videos.
    /// Behandelt Fehler und zeigt gegebenenfalls Favoriten im Offline-Modus an.
    func loadVideos(forceReload: Bool = false) async {
        offlineMessage = nil
        errorMessage = nil // vorherige Fehlermeldung zurücksetzen
        // Session-Guard: dieselbe Playlist nicht mehrfach initial laden (sofern nicht erzwungen)
        if !forceReload, Self.loadedOnce.contains(playlistId), !videos.isEmpty {
            print("🧠 Session-Guard: Initial-Load für \(playlistId) übersprungen (bereits geladen in dieser Session)")
            return
        }
        do {
            let response = try await apiService.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: nil)
            let items = response.items
            self.nextPageToken = response.nextPageToken
            // nextPageToken kommt von der ersten Seite
            let favorites = FavoritesManager.shared.getAllFavorites(context: context)
            self.videos = items.compactMap { item in
                guard
                    let snippet = item.snippet,
                    let videoId = snippet.resourceId?.videoId,
                    let title = snippet.title,
                    let description = snippet.description
                else {
                    return nil
                }
                // Video-ID Normalisierung: Nur reine Video-ID speichern
                let cleanID = Video.extractVideoID(from: videoId)
                let url = cleanID
                
                // Thumbnail Normalisierung: HTTPS erzwingen und maxresdefault verwenden, falls möglich
                var thumbnailURL = snippet.thumbnails?.high?.url ?? snippet.thumbnails?.medium?.url ?? ""
                thumbnailURL = thumbnailURL.replacingOccurrences(of: "http://", with: "https://")
                if let id = snippet.resourceId?.videoId {
                    // Versuch, auf das maxresdefault-Thumbnail zu setzen
                    thumbnailURL = "https://i.ytimg.com/vi/\(id)/maxresdefault.jpg"
                }

                var video = Video(
                    id: UUID(),
                    title: title,
                    description: description,
                    thumbnailURL: thumbnailURL,
                    videoURL: url,
                    category: "YouTube"
                )
                if favorites.contains(where: { $0.videoURL == url }) {
                    video.isFavorite = true
                }
                return video
            }
            // Merken: Diese Playlist wurde in dieser Session bereits einmal geladen
            Self.loadedOnce.insert(self.playlistId)
        } catch let error as AppError {
            switch error {
            case .invalidURL:
                errorMessage = "Ungültige URL. Bitte überprüfe die API-Einstellungen."
            case .networkError:
                // Underlying Error (falls vorhanden) in die Konsole schreiben
                if let underlyingError = (error as LocalizedError).errorDescription {
                    print("Network error occurred: \(underlyingError)")
                }
                let favorites = FavoritesManager.shared.getAllFavorites(context: context)
                if favorites.isEmpty {
                    if let apiErrorMessage = errorMessage, !apiErrorMessage.isEmpty {
                        errorMessage = apiErrorMessage
                    } else {
                        errorMessage = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
                    }
                } else {
                    errorMessage = nil
                    offlineMessage = "Offline-Modus: Zeige gespeicherte Favoriten"
                    self.videos = favorites.map { fav in
                        Video(
                            id: fav.id,
                            title: fav.title,
                            description: fav.videoDescription,
                            thumbnailURL: fav.thumbnailURL,
                            videoURL: fav.videoURL,
                            category: fav.category,
                            isFavorite: true
                        )
                    }
                }
            case .decodingError:
                // Underlying Error (falls vorhanden) in die Konsole schreiben
                if let underlyingError = (error as LocalizedError).errorDescription {
                    print("Decoding error occurred: \(underlyingError)")
                }
                if let apiErrorMessage = errorMessage, !apiErrorMessage.isEmpty {
                    errorMessage = apiErrorMessage
                } else {
                    errorMessage = "Fehler beim Verarbeiten der Daten. Versuche es später erneut."
                }
            case .unknown:
                errorMessage = "Ein unbekannter Fehler ist aufgetreten."
            }
        } catch {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten."
        }
    }

    /// Lädt weitere Videos, falls ein nextPageToken vorhanden ist (Infinite Scroll)
    func loadMoreVideos() async {
        guard !isLoadingMore, let token = nextPageToken, !token.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response = try await apiService.fetchVideos(from: playlistId, apiKey: apiKey, pageToken: token)
            let favorites = FavoritesManager.shared.getAllFavorites(context: context)
            let newVideos: [Video] = response.items.compactMap { item in
                guard
                    let snippet = item.snippet,
                    let videoId = snippet.resourceId?.videoId,
                    let title = snippet.title,
                    let description = snippet.description
                else { return nil }

                // Video-ID Normalisierung: Nur reine Video-ID speichern
                let cleanID = Video.extractVideoID(from: videoId)
                let url = cleanID
                
                // Thumbnail Normalisierung: HTTPS erzwingen und maxresdefault verwenden, falls möglich
                var thumbnailURL = snippet.thumbnails?.high?.url ?? snippet.thumbnails?.medium?.url ?? ""
                thumbnailURL = thumbnailURL.replacingOccurrences(of: "http://", with: "https://")
                if let id = snippet.resourceId?.videoId {
                    // Versuch, auf das maxresdefault-Thumbnail zu setzen
                    thumbnailURL = "https://i.ytimg.com/vi/\(id)/maxresdefault.jpg"
                }

                var video = Video(
                    id: UUID(),
                    title: title,
                    description: description,
                    thumbnailURL: thumbnailURL,
                    videoURL: url,
                    category: "YouTube"
                )
                if favorites.contains(where: { $0.videoURL == url }) {
                    video.isFavorite = true
                }
                return video
            }
            // Duplikate vermeiden: existierende Video-URLs sammeln und nur neue anhängen
            let existingURLs = Set(self.videos.map { $0.videoURL })
            let uniqueNewVideos = newVideos.filter { !existingURLs.contains($0.videoURL) }
            self.videos.append(contentsOf: uniqueNewVideos)
            // Token für die nächste Seite aktualisieren
            self.nextPageToken = response.nextPageToken
        } catch {
            // Kein hartes UI-Feedback nötig; Log genügt für Debugging
            print("Mehr laden fehlgeschlagen:", error.localizedDescription)
        }
    }

    /// Wechselt den Favoritenstatus eines Videos und aktualisiert die Ansicht entsprechend.
    func toggleFavorite(for video: Video) async {
        await FavoritesManager.shared.toggleFavorite(video: video, context: context)
        if let index = videos.firstIndex(of: video) {
            videos[index].isFavorite = FavoritesManager.shared.isFavorite(video: video, context: context)
        }
    }

    @Published var showFavoritesOnly: Bool = false

    var filteredVideos: [Video] {
        return videos.filter { video in
            let matchesSearch = searchText.isEmpty ||
                video.title.localizedCaseInsensitiveContains(searchText) ||
                video.description.localizedCaseInsensitiveContains(searchText) ||
                video.category.localizedCaseInsensitiveContains(searchText)

            let matchesFavorites = !showFavoritesOnly || video.isFavorite

            return matchesSearch && matchesFavorites
        }
    }
}
