
import Foundation

final class FavoritesManager {
    static let shared = FavoritesManager()

    private init() {}

    private var favorites: Set<UUID> = []

    func isFavorite(video: Video) -> Bool {
        return favorites.contains(video.id)
    }

    func toggleFavorite(video: Video) {
        if favorites.contains(video.id) {
            favorites.remove(video.id)
        } else {
            favorites.insert(video.id)
        }
    }

    func getFavorites() -> Set<UUID> {
        return favorites
    }
}
