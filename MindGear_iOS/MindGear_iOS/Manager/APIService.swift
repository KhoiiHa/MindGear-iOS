
import Foundation

final class APIService {
    static let shared = APIService()

    private init() {}

    func fetchVideos(completion: @escaping (Result<[Video], AppError>) -> Void) {
        // Hier später echte API-Calls einfügen
        completion(.failure(.unknown))
    }
}

