//
//  RemoteMappers.swift
//  MindGear_iOS
//
//  Zweck: Mapper von Remote‑Caches (Videos) → App‑Modelle.
//  Architekturrolle: Extension (Adapter‑Pattern).
//  Verantwortung: Thumbnail‑Fallback, HTTPS‑Enforce, Default‑Kategorie.
//  Warum? Trennt Remote‑Schema von Domain‑Modellen; Views nutzen nur `Video`.
//  Testbarkeit: Deterministisch; mit Mock‑Caches einfach prüfbar.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: Nimmt RemoteVideosCache.VideoItem → mappt robust zu `Video` mit HTTPS & Fallback.

// MARK: - VideoItem Mapper
/// Stellt abgeleitete Properties für Remote‑VideoItems bereit.
extension RemoteVideosCache.VideoItem {
    /// Wählt die beste Thumbnail‑URL (Priorität: high → medium → default).
    /// Warum: Liefert konsistente Qualität; robust gegen fehlende Felder.
    var bestThumb: String? {
        thumbnails?.high ?? thumbnails?.medium ?? thumbnails?.`default`
    }
}

// MARK: - Array Mapper
/// Konvertiert eine Liste von Remote‑VideoItems in App‑Videos.
extension Array where Element == RemoteVideosCache.VideoItem {
    /// Mappt alle Remote‑Items auf `Video`.
    /// - Returns: Gefilterte Liste gültiger Videos (mit HTTPS‑Thumbnail & VideoID).
    /// Warum: Schlanke Schnittstelle für ViewModels.
    func mapToVideos() -> [Video] {
        self.compactMap { (item) -> Video? in
            guard let id = item.id else { return nil }
            // Thumbnail‑Fallback: HQ‑Default per VideoID, immer HTTPS
            let thumb = (item.bestThumb ?? "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")
                .replacingOccurrences(of: "http://", with: "https://")
            return Video(
                id: UUID(),
                title: item.title,
                description: item.description,
                thumbnailURL: thumb,
                // Wir speichern nur die Video‑ID (YouTube) – Aufbereitung später im Mapper
                videoURL: id,
                category: "YouTube"
            )
        }
    }
}
