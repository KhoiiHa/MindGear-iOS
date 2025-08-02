import Foundation
import SwiftData

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var offlineMessage: String? = nil

    // Dynamically load API credentials from Config.plist
    private let apiKey = ConfigManager.apiKey
    private let playlistId: String

    private let apiService: APIServiceProtocol
    private var context: ModelContext

    init(playlistId: String, apiService: APIServiceProtocol = APIService.shared, context: ModelContext) {
        self.playlistId = playlistId
        self.apiService = apiService
        self.context = context
    }

    func loadVideos() async {
        do {
            offlineMessage = nil
            let items = try await apiService.fetchVideos(from: playlistId, apiKey: apiKey)
            let favorites = FavoritesManager.shared.getAllFavorites(context: context)
            self.videos = items.compactMap { item in
                guard
                    let snippet = item.snippet,
                    let videoId = snippet.resourceId?.videoId,
                    let title = snippet.title,
                    let description = snippet.description,
                    let thumbnailURL = snippet.thumbnails?.medium?.url
                else {
                    return nil
                }

                let url = "https://www.youtube.com/watch?v=\(videoId)"
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
        } catch let error as AppError {
            switch error {
            case .invalidURL:
                errorMessage = "Ungültige URL. Bitte überprüfe die API-Einstellungen."
            case .networkError:
                let favorites = FavoritesManager.shared.getAllFavorites(context: context)
                if favorites.isEmpty {
                    errorMessage = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
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
                errorMessage = "Fehler beim Verarbeiten der Daten. Versuche es später erneut."
            case .unknown:
                errorMessage = "Ein unbekannter Fehler ist aufgetreten."
            }
        } catch {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten."
        }
    }

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
