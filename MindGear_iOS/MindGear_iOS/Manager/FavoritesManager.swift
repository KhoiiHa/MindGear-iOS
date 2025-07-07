import Foundation
import SwiftData

final class FavoritesManager {
    static let shared = FavoritesManager()

    private init() {}

    func isFavorite(video: Video, context: ModelContext) -> Bool {
        do {
            let results = try context.fetch(FetchDescriptor<FavoriteVideoEntity>())
            return results.contains(where: { $0.id == video.id })
        } catch {
            print("Error checking favorite status: \(error)")
            return false
        }
    }

    func toggleFavorite(video: Video, context: ModelContext) {
        do {
            let results = try context.fetch(FetchDescriptor<FavoriteVideoEntity>())
            if let existing = results.first(where: { $0.id == video.id }) {
                context.delete(existing)
            } else {
                let favorite = FavoriteVideoEntity(
                    id: video.id,
                    title: video.title,
                    videoDescription: video.description,
                    thumbnailURL: video.thumbnailURL,
                    videoURL: video.videoURL,
                    category: video.category
                )
                context.insert(favorite)
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }

    func getAllFavorites(context: ModelContext) -> [FavoriteVideoEntity] {
        do {
            return try context.fetch(FetchDescriptor<FavoriteVideoEntity>())
        } catch {
            print("Error fetching favorites: \(error)")
            return []
        }
    }
}
