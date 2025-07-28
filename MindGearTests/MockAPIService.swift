import Foundation
@testable import MindGear_iOS

class MockAPIService: APIServiceProtocol {
    var result: Result<[YouTubeVideoItem], Error>

    init(result: Result<[YouTubeVideoItem], Error>) {
        self.result = result
    }

    func fetchVideos(from playlistId: String, apiKey: String) async throws -> [YouTubeVideoItem] {
        switch result {
        case .success(let items):
            return items
        case .failure(let error):
            throw error
        }
    }
}
