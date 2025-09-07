//
//  FavoriteVideoEntity.swift
//  MindGear_iOS
//
//  Zweck: SwiftData‑Entity für gespeicherte Video‑Favoriten.
//  Architekturrolle: Persistence‑Model (SwiftData).
//  Verantwortung: Speichert Video‑ID, Titel, Beschreibung, Thumbnail, Kategorie & Zeitstempel.
//  Warum? Einheitliche Persistenz; klare Trennung zwischen Remote/API und lokaler Speicherung.
//  Testbarkeit: Deterministisch; leicht mit In‑Memory ModelContainer prüfbar.
//  Status: stabil.
//

import Foundation
import SwiftData

// Kurzzusammenfassung: Speichert Video‑Favoriten mit ID, Titel, Beschreibung, Thumbnail, Kategorie & CreatedAt.

// MARK: - FavoriteVideoEntity
/// SwiftData‑Entity für Video‑Favoriten (UUID als Primary Key).
@Model
final class FavoriteVideoEntity {
    // Primärschlüssel: UUID für das Video (eindeutig)
    @Attribute(.unique) var id: UUID
    // Titel des Videos
    var title: String
    // Beschreibung des Videos
    var videoDescription: String
    // Thumbnail‑URL (HTTPS bevorzugt)
    var thumbnailURL: String
    // YouTube‑Video‑URL oder ID
    var videoURL: String
    // Kategorie des Videos (z. B. Mindset, Fokus)
    var category: String
    // Optional zwischengespeichertes Bild (für Offline‑Modus)
    var thumbnailData: Data?
    // Zeitpunkt des Favorisierens → erlaubt Sortierung/History
    var createdAt: Date
    // Typdifferenzierung (z. B. gegen Mentor/Playlist‑Favoriten)
    var type: String = "video"

    init(id: UUID, title: String, videoDescription: String, thumbnailURL: String, videoURL: String, category: String, thumbnailData: Data? = nil, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.videoDescription = videoDescription
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.category = category
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
        self.type = "video"
    }
}
