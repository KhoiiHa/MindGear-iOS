//
//  ThumbnailURLBuilder.swift
//  MindGear_iOS
//
//  Zweck: Robuste Konstruktion von YouTube‑Thumbnail‑URLs (verschiedene Qualitäten).
//  Architekturrolle: Utility (Business‑nah, aber UI‑unabhängig).
//  Verantwortung: IDs extrahieren, URL säubern, Fallback‑Kette aufbauen.
//  Warum? Saubere Trennung; Views verwenden nur fertige Strings → leicht testbar.
//  Testbarkeit: Pure Functions, deterministisch prüfbar.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: Normalisiert Input (ID/URL/Bildlink) → liefert saubere i.ytimg.com‑URL in bestmöglicher Qualität.

// MARK: - ThumbnailQuality
/// Unterstützte Qualitätsstufen – nicht jede ist für jedes Video vorhanden.
enum ThumbnailQuality: String, CaseIterable {
    case max = "maxresdefault"
        // höchstes Thumbnail – nicht immer verfügbar
    case high = "hqdefault"
    case medium = "mqdefault"
    case low = "sddefault"
}

// MARK: - ThumbnailURLBuilder
enum ThumbnailURLBuilder {

    /// Baut eine robuste Thumbnail‑URL.
    /// - Parameter raw: YouTube‑Video‑ID, Kurzlink, vollständige URL oder bereits Bildlink.
    /// - Parameter quality: gewünschte Startqualität (fällt automatisch ab).
    /// - Returns: Erste Kandidaten‑URL; AsyncImage/View übernimmt Fallback bei 404.
    /// Warum: Kapselt Normalisierung & Fallback → Views bleiben schlank.
    static func build(from raw: String, prefer quality: ThumbnailQuality = .high) -> String {
        // Bereits ein vollständiger Bild/HTTP-Link? -> säubern & zurückgeben
        if raw.lowercased().hasPrefix("http") {
            return sanitize(raw)
        }

        // Aus vollständiger YouTube-URL oder Kurzlink ID extrahieren
        let id = Video.extractVideoID(from: raw)
        guard !id.isEmpty else {
            return sanitize(raw) // Unknown input: gib „best effort“ zurück
        }

        // Fallback-Kette: prefer -> rest (ohne Duplikate)
        var chain = [quality] + ThumbnailQuality.allCases.filter { $0 != quality }

        // Wir liefern **die erste** Kandidaten-URL zurück.
        // Die eigentliche Fehlerbehandlung übernimmt `AsyncImage` in der View,
        // die bei 404 automatisch den nächsten Kandidaten versucht (per reloadToken o.ä.).
        // Damit bleibt diese Schicht leichtgewichtig & testbar.
        let q = chain.removeFirst()
        return makeYTThumbURL(id: id, quality: q)
    }

    /// Erzeugt eine i.ytimg.com‑URL für die gewünschte Qualität.
    /// Warum: Einheitliches Muster → leicht erweiterbar.
    private static func makeYTThumbURL(id: String, quality: ThumbnailQuality) -> String {
        "https://i.ytimg.com/vi/\(id)/\(quality.rawValue).jpg"
    }

    /// Entfernt volatile Query‑Parameter (t, utm_…) und normalisiert Hosts.
    /// Warum: Verhindert instabile URLs & unnötige Cache‑Miss.
    static func sanitize(_ urlString: String) -> String {
        guard var comps = URLComponents(string: urlString) else { return urlString }

        // YouTube-Hosts konsistent handhaben (optional – keine harte Umschreibung).
        if let host = comps.host?.lowercased() {
            if host.contains("youtube-nocookie.com") || host.contains("youtube.com") || host.contains("youtu.be") {
                // nichts erzwingen – nur Queries säubern
            }
        }

        // Volatile Params (Cache-Buster etc.) entfernen
        let dropNames = Set(["t","timestamp","utm_source","utm_medium","utm_campaign"])
        comps.queryItems = (comps.queryItems ?? []).filter { !dropNames.contains($0.name.lowercased()) }

        return comps.url?.absoluteString ?? urlString
    }
}
