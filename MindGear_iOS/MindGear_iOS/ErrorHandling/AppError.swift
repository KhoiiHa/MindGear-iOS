import Foundation

enum AppError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die URL ist ungültig."
        case .networkError:
            return "Es ist ein Netzwerkfehler aufgetreten."
        case .decodingError:
            return "Die Daten konnten nicht verarbeitet werden."
        case .unknown:
            return "Ein unbekannter Fehler ist aufgetreten."
        }
    }
}
