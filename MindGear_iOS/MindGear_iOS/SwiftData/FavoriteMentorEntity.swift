//
//  FavoriteMentorEntity.swift
//  MindGear_iOS
//
//  Zweck: SwiftData‑Entity für gespeicherte Mentor‑Favoriten.
//  Architekturrolle: Persistence‑Model (SwiftData).
//  Verantwortung: Speichert Channel‑ID, Name, Profilbild & Zeitstempel.
//  Warum? Einheitliche Persistenz; klare Trennung zwischen Remote/API und lokaler Speicherung.
//  Testbarkeit: Deterministisch; leicht mit In‑Memory ModelContainer prüfbar.
//  Status: stabil.
//

import Foundation
import SwiftData

// Kurzzusammenfassung: Speichert Mentor‑Favoriten mit ID, Name, optionalem Bild & CreatedAt.

// MARK: - FavoriteMentorEntity
/// SwiftData‑Entity für Mentor‑Favoriten (Channel‑ID als Primary Key).
@Model
final class FavoriteMentorEntity {
    // Primärschlüssel: YouTube‑Channel‑ID (eindeutig)
    @Attribute(.unique) var id: String
    // Anzeigename (für Favoriten‑Liste)
    var name: String
    // Optionales Profilbild (Thumbnail‑URL)
    var profileImageURL: String?
    // Zeitpunkt des Speicherns → erlaubt Sortierung/History
    var createdAt: Date
    // Typdifferenzierung (z. B. gegen Video/Playlist‑Favoriten)
    var type: String = "mentor"

    init(id: String, name: String, profileImageURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.type = "mentor"
    }
}
