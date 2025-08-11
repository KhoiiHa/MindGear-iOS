// Notification.Name-Erweiterung für Favoriten-Änderungen
extension Notification.Name {
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
}

import Foundation
import SwiftData

// Diese Datei verwaltet Favoriten für Videos und Mentoren.
// Sie ermöglicht das Speichern, Abrufen und Verwalten von Favoriten, um Nutzern eine personalisierte Erfahrung zu bieten.


@MainActor
final class FavoritesManager {
    static let shared = FavoritesManager()

    private init() {}

    // Prüft, ob ein Video als Favorit markiert ist ✅
    func isVideoFavorite(video: Video, context: ModelContext) -> Bool {
        do {
            let vid = video.id
            let descriptor = FetchDescriptor<FavoriteVideoEntity>(
                predicate: #Predicate { $0.id == vid }
            )
            return try !context.fetch(descriptor).isEmpty
        } catch {
            print("Error checking video favorite status:", error)
            return false
        }
    }

    // Prüft, ob der Mentor als Favorit gespeichert ist
    func isMentorFavorite(mentor: Mentor, context: ModelContext) -> Bool {
        do {
            let cid = mentor.channelId
            let descriptor = FetchDescriptor<FavoriteMentorEntity>(
                predicate: #Predicate { $0.id == cid }
            )
            return try !context.fetch(descriptor).isEmpty
        } catch {
            print("Error checking mentor favorite status:", error)
            return false
        }
    }

    // Schaltet den Favoritenstatus eines Videos um (hinzufügen oder entfernen)
    func toggleVideoFavorite(video: Video, context: ModelContext) async {
        do {
            let vid = video.id
            let descriptor = FetchDescriptor<FavoriteVideoEntity>(
                predicate: #Predicate { $0.id == vid }
            )
            if let existing = try context.fetch(descriptor).first {
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
            do { try context.save() } catch { print("Save failed (video favorite):", error) }
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("Error toggling video favorite:", error)
        }
    }

    // Schaltet den Favoritenstatus eines Mentors um
    func toggleMentorFavorite(mentor: Mentor, context: ModelContext) async {
        do {
            let cid = mentor.channelId
            let descriptor = FetchDescriptor<FavoriteMentorEntity>(
                predicate: #Predicate { $0.id == cid }
            )
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
            } else {
                let favorite = FavoriteMentorEntity(
                    id: mentor.channelId,
                    name: mentor.name,
                    profileImageURL: mentor.profileImageURL
                )
                context.insert(favorite)
            }
            do { try context.save() } catch { print("Save failed (mentor favorite):", error) }
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("Error toggling mentor favorite:", error)
        }
    }

    private func downloadThumbnail(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    /// Liefert alle gespeicherten Video-Favoriten zurück 📂
    func getAllVideoFavorites(context: ModelContext) -> [FavoriteVideoEntity] {
        do {
            return try context.fetch(FetchDescriptor<FavoriteVideoEntity>())
        } catch {
            print("Error fetching video favorites: \(error)")
            return []
        }
    }

    /// Gibt alle gespeicherten Mentor-Favoriten zurück 📋
    func getAllMentorFavorites(context: ModelContext) -> [FavoriteMentorEntity] {
        do {
            return try context.fetch(FetchDescriptor<FavoriteMentorEntity>())
        } catch {
            print("Error fetching mentor favorites: \(error)")
            return []
        }
    }

    // Prüft, ob eine Playlist als Favorit gespeichert ist
    func isPlaylistFavorite(id: String, context: ModelContext) -> Bool {
        do {
            let descriptor = FetchDescriptor<FavoritePlaylistEntity>(
                predicate: #Predicate { $0.id == id }
            )
            return try !context.fetch(descriptor).isEmpty
        } catch {
            print("Error checking playlist favorite status:", error)
            return false
        }
    }

    // Schaltet den Favoritenstatus einer Playlist um
    func togglePlaylistFavorite(id: String, title: String, thumbnailURL: String, context: ModelContext) async {
        do {
            let descriptor = FetchDescriptor<FavoritePlaylistEntity>(
                predicate: #Predicate { $0.id == id }
            )
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
            } else {
                let favorite = FavoritePlaylistEntity(
                    id: id,
                    title: title,
                    thumbnailURL: thumbnailURL
                )
                context.insert(favorite)
            }
            do { try context.save() } catch { print("Save failed (playlist favorite):", error) }
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("Error toggling playlist favorite:", error)
        }
    }

    /// Gibt alle gespeicherten Playlist-Favoriten zurück
    func getAllPlaylistFavorites(context: ModelContext) -> [FavoritePlaylistEntity] {
        do {
            return try context.fetch(FetchDescriptor<FavoritePlaylistEntity>())
        } catch {
            print("Error fetching playlist favorites: \(error)")
            return []
        }
    }

}
