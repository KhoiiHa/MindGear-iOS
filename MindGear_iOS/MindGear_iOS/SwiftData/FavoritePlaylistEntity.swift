//
//  FavoritePlaylistEntity.swift
//  MindGear_iOS
//
//  Zweck: SwiftData‑Entity für gespeicherte Playlist‑Favoriten.
//  Architekturrolle: Persistence‑Model (SwiftData).
//  Verantwortung: Speichert Playlist‑ID, Titel, Thumbnail, optionale Beschreibung & Zeitstempel.
//  Warum? Einheitliche Persistenz; klare Trennung zwischen Remote/API und lokaler Speicherung.
//  Testbarkeit: Deterministisch; leicht mit In‑Memory ModelContainer prüfbar.
//  Status: stabil.
//

import Foundation
import SwiftData

// Kurzzusammenfassung: Speichert Playlist‑Favoriten mit ID, Titel, Thumbnail, optionaler Beschreibung & CreatedAt.

// MARK: - FavoritePlaylistEntity
/// SwiftData‑Entity für Playlist‑Favoriten (Playlist‑ID als Primary Key).
@Model
final class FavoritePlaylistEntity {
    // Primärschlüssel: YouTube‑Playlist‑ID (eindeutig)
    @Attribute(.unique) var id: String

    // Titel der Playlist (zum Zeitpunkt des Favorisierens gespeichert)
    var title: String

    // Optionale Beschreibung (falls vorhanden)
    var playlistDescription: String?

    // Thumbnail‑URL (HTTPS bevorzugt)
    var thumbnailURL: String

    // Zeitpunkt des Favorisierens → erlaubt Sortierung/History
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
