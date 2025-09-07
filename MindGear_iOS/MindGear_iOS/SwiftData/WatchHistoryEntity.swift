//
//  WatchHistoryEntity.swift
//  MindGear_iOS
//
//  Zweck: SwiftData‑Entity für den Video‑Verlauf („Zuletzt gesehen“).
//  Architekturrolle: Persistence‑Model (SwiftData).
//  Verantwortung: Speichert Video‑ID, Titel, Thumbnail, Zeitpunkt & Wiedergabeposition.
//  Warum? Verlauf erleichtert Wiedereinstieg; Trennung zwischen Remote/API und lokaler Speicherung.
//  Testbarkeit: Deterministisch; leicht mit In‑Memory ModelContainer prüfbar.
//  Status: stabil.
//

import Foundation
import SwiftData

// Kurzzusammenfassung: Speichert Video‑History mit ID, Titel, Thumbnail, Zeitstempel & Fortschrittsanzeige.

// MARK: - WatchHistoryEntity
/// SwiftData‑Entity für Video‑History („Zuletzt gesehen“).
@Model
final class WatchHistoryEntity {
    /// YouTube‑Video‑ID (eindeutig)
    @Attribute(.unique) var videoId: String

    /// Titel des Videos
    var title: String

    /// Thumbnail‑URL als String (HTTPS bevorzugt)
    var thumbnailURL: String

    /// Zeitpunkt des letzten Ansehens (für Sortierung)
    var watchedAt: Date

    /// (Optional) Letzte Wiedergabeposition in Sekunden – für späteres Resume/Progress
    var lastPosition: Double

    /// Basis‑Initializer für das Speichern im Verlauf
    init(videoId: String,
         title: String,
         thumbnailURL: String,
         watchedAt: Date = .now,
         lastPosition: Double = 0) {
        self.videoId = videoId
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.watchedAt = watchedAt
        self.lastPosition = lastPosition
    }
}
