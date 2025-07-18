import Foundation

final class APIService {
    static let shared = APIService()

    private init() {}

    func fetchVideos(from playlistId: String, apiKey: String) async throws -> [YouTubeVideoItem] {
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=10&playlistId=\(playlistId)&key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AppError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            do {
                let response = try JSONDecoder().decode(YouTubeResponse.self, from: data)
                return response.items
            } catch {
                throw AppError.decodingError
            }
        } catch {
            throw AppError.networkError
        }
    }
}
