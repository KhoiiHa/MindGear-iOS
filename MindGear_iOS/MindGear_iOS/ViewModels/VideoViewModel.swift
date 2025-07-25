import Foundation

/// ViewModel steuert das Laden und Filtern der Videos.
/// Einfach gehalten, damit der Einstieg in SwiftUI klar bleibt.

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false

    // Dynamically load API credentials from Config.plist
    private let apiKey = ConfigManager.apiKey
    private let playlistId = ConfigManager.playlistId

    /// Lädt die Videos der konfigurierten YouTube-Playlist.
    /// Zeigt einen Ladeindikator und fängt einfache Fehler ab.
    func loadVideos() async {
        isLoading = true
        defer { isLoading = false }
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

    /// Gibt Videos basierend auf Suchbegriff und Favoritenstatus zurück.
    var filteredVideos: [Video] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let search = trimmed.lowercased()

        return videos.filter { video in
            let matchesSearch = search.isEmpty ||
                video.title.lowercased().contains(search) ||
                video.description.lowercased().contains(search) ||
                video.category.lowercased().contains(search)

            let matchesFavorites = !showFavoritesOnly || video.isFavorite

            return matchesSearch && matchesFavorites
        }
    }
}
