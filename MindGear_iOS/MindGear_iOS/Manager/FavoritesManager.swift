//
//  FavoritesManager.swift
//  MindGear_iOS
//
//  Zweck: Zentrale Verwaltung aller Favoriten (Videos, Mentoren, Playlists) mit SwiftData + Fallback über UserDefaults.
//  Architekturrolle: Service/Manager (State-Fassade für persistente Favoriten inkl. UI-Notifikationen).
//  Verantwortung: Lesen/Schreiben, Deduplikation, Benachrichtigung, Vorschaubild-Download.
//  Warum? Entkoppelt Views/ViewModels von Persistenzdetails; konsistente API & leichte Testbarkeit.
//  Testbarkeit: @MainActor-Grenzen klar, SwiftData über `ModelContext` mock-/injektionsfähig; UserDefaults-Teil deterministisch.
//  Status: stabil.
//

// MARK: - Notifications
// Warum: UI kann auf Änderungen reagieren (Listen refreshen, Badges updaten)

extension Notification.Name {
    /// Wird gesendet, wenn sich ein Favoriten-Eintrag ändert (Video/Mentor/Playlist)
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
}

import Foundation
import SwiftData

// Verwaltet Favoriten (SwiftData-Entities) plus einfachen ID-Fallback über UserDefaults

// Verwalten aller Favoritenarten für personalisierte Inhalte
final class FavoritesManager {
    static let shared = FavoritesManager()

    // MARK: - Init
    init() {}

    // MARK: - State
    private let defaultsKey = "simpleFavorites"
    private let defaults = UserDefaults.standard

    // MARK: - Video
    @MainActor
    /// Prüft, ob ein Video als Favorit markiert ist.
    /// Warum: Schneller Lookup über SwiftData (id‑basiert) für deterministisches UI‑Binding.
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

    @MainActor
    /// Prüft, ob ein Mentor als Favorit gespeichert ist.
    /// Warum: Einheitliche Abfrage für Badge/Toggle‑Zustände.
    func isMentorFavorite(mentor: Mentor, context: ModelContext) -> Bool {
        do {
            let mid = mentor.id
            let descriptor = FetchDescriptor<FavoriteMentorEntity>(
                predicate: #Predicate { $0.id == mid }
            )
            return try !context.fetch(descriptor).isEmpty
        } catch {
            print("Error checking mentor favorite status:", error)
            return false
        }
    }

    @MainActor
    /// Schaltet den Favoritenstatus eines Videos um.
    /// Warum: Kapselt Insert/Delete + optionalen Thumbnail‑Download; sendet Änderung via Notification.
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
                    thumbnailData: data,
                    createdAt: .now
                )
                context.insert(favorite)
            }
            do { try context.save() } catch { print("Save failed (video favorite):", error) }
            // UI informieren: Listen/Badges können unmittelbar neu laden.
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("Error toggling video favorite:", error)
        }
    }

    @MainActor
    /// Schaltet den Favoritenstatus eines Mentors um.
    /// Warum: Kapselt Insert/Delete und benachrichtigt die UI zentral.
    func toggleMentorFavorite(mentor: Mentor, context: ModelContext) async {
        do {
            let mid = mentor.id
            let descriptor = FetchDescriptor<FavoriteMentorEntity>(
                predicate: #Predicate { $0.id == mid }
            )
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
            } else {
                let favorite = FavoriteMentorEntity(
                    id: mentor.id,
                    name: mentor.name,
                    profileImageURL: mentor.profileImageURL
                )
                context.insert(favorite)
            }
            do { try context.save() } catch { print("Save failed (mentor favorite):", error) }
            // UI informieren: State konsistent halten (z. B. Favoritenliste aktualisieren).
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("Error toggling mentor favorite:", error)
        }
    }

    /// Lädt das Thumbnail für Offline‑/Sofortdarstellung lokal.
    /// Warum: Schnellere Favoriten‑Listen; vermeidet „springende“ Layouts bei erneutem Laden.
    private func downloadThumbnail(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    @MainActor
    /// Liefert alle gespeicherten Video‑Favoriten (neueste zuerst).
    /// Warum: Einheitliche Sortierung für UI‑Listen.
    func getAllVideoFavorites(context: ModelContext) -> [FavoriteVideoEntity] {
        do {
            let descriptor = FetchDescriptor<FavoriteVideoEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching video favorites: \(error)")
            return []
        }
    }

    @MainActor
    /// Gibt alle gespeicherten Mentor‑Favoriten zurück.
    /// Warum: Vereinheitlichte Datenquelle für Favoriten‑Screens.
    func getAllMentorFavorites(context: ModelContext) -> [FavoriteMentorEntity] {
        do {
            return try context.fetch(FetchDescriptor<FavoriteMentorEntity>())
        } catch {
            print("Error fetching mentor favorites: \(error)")
            return []
        }
    }

    // MARK: - Playlist
    @MainActor
    /// Prüft, ob eine Playlist als Favorit gespeichert ist.
    /// Warum: Id‑basierter Lookup; deterministisches Binding für Toggle/Buttons.
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

    @MainActor
    /// Fügt eine Playlist als Favorit hinzu, falls noch nicht vorhanden.
    func addPlaylistFavorite(id: String, title: String, thumbnailURL: String = "", context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<FavoritePlaylistEntity>(
                predicate: #Predicate { $0.id == id }
            )
            if try context.fetch(descriptor).first == nil {
                let favorite = FavoritePlaylistEntity(
                    id: id,
                    title: title,
                    thumbnailURL: thumbnailURL
                )
                context.insert(favorite)
                do { try context.save() } catch { print("Save failed (add playlist favorite):", error) }
                NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
            }
        } catch {
            print("Error adding playlist favorite:", error)
        }
    }

    @MainActor
    /// Entfernt eine Playlist aus den Favoriten, falls vorhanden.
    func removePlaylistFavorite(id: String, context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<FavoritePlaylistEntity>(
                predicate: #Predicate { $0.id == id }
            )
            if let existing = try context.fetch(descriptor).first {
                context.delete(existing)
                do { try context.save() } catch { print("Save failed (remove playlist favorite):", error) }
                NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
            }
        } catch {
            print("Error removing playlist favorite:", error)
        }
    }

    @MainActor
    /// Schaltet den Favoritenstatus einer Playlist um.
    /// Warum: Kapselt Insert/Delete und benachrichtigt die UI zentral.
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
            // UI informieren: Konsistentes Refresh der Favoriten‑Views.
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        } catch {
            print("Error toggling playlist favorite:", error)
        }
    }

    @MainActor
    /// Gibt alle gespeicherten Playlist-Favoriten zurück
    func getAllPlaylistFavorites(context: ModelContext) -> [FavoritePlaylistEntity] {
        do {
            let descriptor = FetchDescriptor<FavoritePlaylistEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Error fetching playlist favorites: \(error)")
            return []
        }
    }

    // MARK: - Einfache Favoriten nach ID (UserDefaults)
    // Warum: Leichter Fallback für einfache Fälle ohne SwiftData‑Entity.

    /// Schaltet den Favoritenstatus für eine beliebige ID um (UserDefaults‑basiert).
    /// Warum: Minimaler Persistenz‑Overhead, kein Schema erforderlich.
    func toggle(_ id: String) {
        var items = Set(all())
        if items.contains(id) {
            items.remove(id)
        } else {
            items.insert(id)
        }
        defaults.set(Array(items), forKey: defaultsKey)
    }

    /// Prüft, ob eine ID als Favorit hinterlegt ist (UserDefaults‑Fallback).
    func isFavorite(_ id: String) -> Bool {
        return all().contains(id)
    }

    /// Liefert alle gespeicherten Favoriten‑IDs (UserDefaults).
    func all() -> [String] {
        return defaults.stringArray(forKey: defaultsKey) ?? []
    }

    /// Entfernt eine ID aus den Favoriten (UserDefaults).
    func remove(_ id: String) {
        var items = all()
        items.removeAll { $0 == id }
        defaults.set(items, forKey: defaultsKey)
    }

}
