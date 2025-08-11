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
/// Minimaler Umfang (MVP):
///  - `id`: YouTube‑Playlist‑ID (eindeutig)
///  - `title`: Anzeigename
///  - `thumbnailURL`: Vorschaubild‑URL (String)
///  - `createdAt`: Zeitpunkt des Hinzufügens (für Sortierung)
///
/// **Hinweis:**
/// Diese Klasse ist für die Nutzung mit SwiftData optimiert und kann bei Bedarf
/// leicht um Codable erweitert werden, falls eine Synchronisation mit einer API
/// oder JSON-Export notwendig wird.
///
/// **Beispiel:**
/// ```swift
/// let playlist = FavoritePlaylistEntity(
///     id: "PL12345",
///     title: "Motivation Mix",
///     thumbnailURL: "https://img.youtube.com/vi/xyz/default.jpg"
/// )
/// modelContext.insert(playlist)
/// try? modelContext.save()
/// ```
///
/// // MARK: - CodingKeys
/// // Falls Decodable/Encodable in Zukunft benötigt wird:
/// // enum CodingKeys: String, CodingKey {
/// //     case id, title, thumbnailURL, createdAt
/// // }
@Model
final class FavoritePlaylistEntity {
    /// Eindeutiger Schlüssel = YouTube‑Playlist‑ID
    @Attribute(.unique) var id: String

    /// Titel der Playlist (zum Zeitpunkt des Favorisierens gespeichert)
    var title: String

    /// Optionale Beschreibung der Playlist (um Konflikte mit 'description' zu vermeiden)
    var playlistDescription: String?

    /// Thumbnail‑URL (HTTPS bevorzugt)
    var thumbnailURL: String

    /// Zeitpunkt, wann diese Playlist als Favorit gespeichert wurde
    var createdAt: Date

    init(id: String, title: String, thumbnailURL: String, playlistDescription: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.playlistDescription = playlistDescription
        self.thumbnailURL = thumbnailURL
        self.createdAt = createdAt
    }
}
