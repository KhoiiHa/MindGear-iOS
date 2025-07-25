import Foundation

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""

    // Dynamically load API credentials from Config.plist
    private let apiKey = ConfigManager.apiKey
    private let playlistId = ConfigManager.playlistId

    func loadVideos() async {
        do {
            let items = try await APIService.shared.fetchVideos(from: playlistId, apiKey: apiKey)
            self.videos = items.map { item in
                Video(
                    id: UUID(),
                    title: item.snippet.title,
                    description: item.snippet.description,
                    thumbnailURL: item.snippet.thumbnails.medium.url,
                    videoURL: "", // To be improved later
                    category: "YouTube"
                )
            }
        } catch let error as AppError {
            switch error {
            case .invalidURL:
                errorMessage = "Ungültige URL. Bitte überprüfe die API-Einstellungen."
            case .networkError:
                errorMessage = "Netzwerkfehler. Bitte überprüfe deine Internetverbindung."
            case .decodingError:
                errorMessage = "Fehler beim Verarbeiten der Daten. Versuche es später erneut."
            case .unknown:
                errorMessage = "Ein unbekannter Fehler ist aufgetreten."
            }
        } catch {
            errorMessage = "Ein unerwarteter Fehler ist aufgetreten."
        }
    }

    func toggleFavorite(for video: Video) {
        if let index = videos.firstIndex(of: video) {
            videos[index].isFavorite.toggle()
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
