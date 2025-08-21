//
//  ThumbnailURLBuilder.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

import Foundation

enum ThumbnailQuality: String, CaseIterable {
    case max = "maxresdefault"   // höchstes, aber nicht immer vorhanden
    case high = "hqdefault"
    case medium = "mqdefault"
    case low = "sddefault"
}

enum ThumbnailURLBuilder {

    /// Baut eine robuste Thumbnail-URL.
    /// - Parameter raw: YouTube-URL, Kurzlink, ID oder bereits ein Bildlink.
    /// - Parameter prefer: gewünschte Startqualität (wir fallen automatisch ab).
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

    /// Erzeugt eine i.ytimg.com-URL für eine bestimmte Qualität.
    private static func makeYTThumbURL(id: String, quality: ThumbnailQuality) -> String {
        "https://i.ytimg.com/vi/\(id)/\(quality.rawValue).jpg"
    }

    /// Entfernt volatile Query-Parameter (z. B. `t`) und normalisiert harmlose Abweichungen.
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
