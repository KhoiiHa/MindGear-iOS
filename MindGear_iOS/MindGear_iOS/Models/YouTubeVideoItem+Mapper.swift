//
//  YouTubeVideoItem+Mapper.swift
//  MindGear_iOS
//
//  Zweck: Mapper von YouTubeVideoItem (API‑Schema) → Video (App‑Domain‑Modell).
//  Architekturrolle: Extension (Adapter‑Pattern).
//  Verantwortung: Defensive Validierung, Thumbnail‑Fallback, Privacy‑Filter.
//  Warum? Trennung von API‑Schema & App‑Modell; Views arbeiten nur mit Video.
//  Testbarkeit: Deterministisch; leicht mit Fixture‑JSON prüfbar.
//  Status: stabil.
//

import Foundation

// Kurzzusammenfassung: Nimmt API‑Response, prüft Pflichtfelder, mappt auf Video mit Thumbnail‑Fallback & Privacy‑Filter.

// MARK: - Mapper
extension YouTubeVideoItem {
    /// Mappt ein `YouTubeVideoItem` in ein internes `Video`‑Modell.
    /// - Parameter category: Kategorie, in die das Video einsortiert wird.
    /// - Returns: Video oder `nil`, falls Pflichtfelder fehlen oder Video privat ist.
    /// Warum: Defensive Logik kapseln; Views müssen nicht selbst prüfen.
    func toVideo(category: String) -> Video? {
        // Pflicht: snippet + videoId → sonst nil
        guard let snippet = snippet, let videoId = snippet.resourceId?.videoId else {
            return nil
        }

        // Titel/Beschreibung optional abfedern
        let rawTitle = snippet.title ?? ""
        let rawDescription = snippet.description ?? ""

        // Private/gesperrte Inhalte überspringen (robuster, auch wenn nur Titel vorhanden ist)
        let isPrivateTitle = rawTitle.lowercased().contains("private")
        let isPrivateDesc  = rawDescription.lowercased().contains("this video is private")
        if isPrivateTitle || isPrivateDesc {
            return nil
        }

        // Thumbnail-Auswahl: maxres -> standard -> high -> medium -> default; Fallback zu i.ytimg.com
        func firstNonEmpty(_ candidates: String?...) -> String? {
            for c in candidates {
                if let s = c?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                    return s
                }
            }
            return nil
        }
        let t = snippet.thumbnails
        // Thumbnail‑Priorität: maxres → standard → high → medium → default
        let candidateThumb = firstNonEmpty(
            t?.maxres?.url,
            t?.standard?.url,
            t?.high?.url,
            t?.medium?.url,
            t?.defaultThumbnail?.url
        )
        let thumbnailURL = candidateThumb ?? "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg"
        // HTTPS erzwingen (ATS‑Konformität)
        let secureThumb = thumbnailURL.replacingOccurrences(of: "http://", with: "https://")

        // Endgültiges Video‑Domain‑Objekt bauen
        return Video(
            id: UUID(), // intern verwendete UUID; die eigentliche Video-Id steckt in videoURL
            title: rawTitle.isEmpty ? "Unbenannter Titel" : rawTitle,
            description: rawDescription,
            thumbnailURL: secureThumb,
            videoURL: "https://www.youtube-nocookie.com/embed/\(videoId)?playsinline=1",
            category: category
        )
    }
}
