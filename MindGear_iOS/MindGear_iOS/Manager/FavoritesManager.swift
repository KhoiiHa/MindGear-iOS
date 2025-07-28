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

    func toggleFavorite(video: Video, context: ModelContext) async {
        do {
            let results = try context.fetch(FetchDescriptor<FavoriteVideoEntity>())
            if let existing = results.first(where: { $0.id == video.id }) {
                context.delete(existing)
            } else {
                var data: Data? = nil
                if let url = URL(string: video.thumbnailURL) {
                    data = try? await downloadThumbnail(from: url)
                }
                let favorite = FavoriteVideoEntity(
                    id: video.id,
                    title: video.title,
                    videoDescription: video.description,
                    thumbnailURL: video.thumbnailURL,
                    videoURL: video.videoURL,
                    category: video.category,
                    thumbnailData: data
                )
                context.insert(favorite)
            }
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }

    private func downloadThumbnail(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
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
