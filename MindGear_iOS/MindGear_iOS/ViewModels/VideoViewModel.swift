import Foundation

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var errorMessage: String? = nil

    // Temporarily hardcode API credentials (later move to secure storage)
    private let apiKey = "AIzaSyDOl0c6scnoCOouZvf9Rsynzac4O30_Sb4" // Replace with your actual API key
    private let playlistId = "YOUR_PLAYLIST_ID" // Replace with your actual playlist ID

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
}
