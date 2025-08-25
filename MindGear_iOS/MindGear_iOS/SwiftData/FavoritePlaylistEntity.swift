//
//  FavoritePlaylistEntity.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 11.08.25.
//

import Foundation
import SwiftData

/// SwiftData‑Modell: Favorisierte YouTube‑Playlist
///
/// Eigenschaften:
///  - `id`: YouTube‑Playlist‑ID (eindeutig; für Navigation genutzt)
///  - `title`: Anzeigename
///  - `thumbnailURL`: Vorschaubild‑URL (String)
///  - `playlistDescription`: Optionale Beschreibung
///  - `createdAt`: Zeitpunkt des Hinzufügens (für Sortierung)
///
/// **Beispiel:**
/// ```swift
/// let playlist = FavoritePlaylistEntity(
///     id: "PL12345", // YouTube-Playlist-ID
///     title: "Motivation Mix",
///     thumbnailURL: "https://img.youtube.com/vi/xyz/default.jpg"
/// )
/// modelContext.insert(playlist)
/// try? modelContext.save()
/// ```
@Model
final class FavoritePlaylistEntity {
    /// Gespeicherte YouTube‑Playlist-ID (wird für Navigation genutzt)
    @Attribute(.unique) var id: String

    /// Titel der Playlist (zum Zeitpunkt des Favorisierens gespeichert)
    var title: String

    /// Optionale Beschreibung der Playlist (um Konflikte mit 'description' zu vermeiden)
    var playlistDescription: String?

    /// Thumbnail‑URL (HTTPS bevorzugt)
    var thumbnailURL: String

    /// Zeitpunkt, wann diese Playlist als Favorit gespeichert wurde
    var createdAt: Date

    init(
        id: String,
        title: String,
        thumbnailURL: String,
        playlistDescription: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.playlistDescription = playlistDescription
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
    }
}
