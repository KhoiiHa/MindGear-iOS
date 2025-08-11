import Foundation
import SwiftData

/// SwiftData-Modell für den Video‑Verlauf ("Zuletzt gesehen").
///
/// Minimaler MVP‑Umfang:
///  - `videoId`: YouTube‑Video-ID (eindeutig pro Eintrag)
///  - `title`: Titel zum Zeitpunkt des Ansehens (damit verlustfrei anzeigbar)
///  - `thumbnailURL`: Vorschaubild (als String, optional später mit Data‑Cache erweiterbar)
///  - `watchedAt`: Zeitpunkt, wann der Nutzer das Video angesehen hat (Sortierung DESC)
///  - `lastPosition`: Reserviert für spätere Fortschrittsanzeige (Sekunden)
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
