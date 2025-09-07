//
//  Video.swift
//  MindGear_iOS
//
//  Zweck: Datenmodell für Videos inkl. Titel, Beschreibung, Thumbnail & YouTube‑ID.
//  Architekturrolle: Model (Codable, Hashable, Identifiable).
//  Verantwortung: Einheitliche Struktur für API/Seeds; Referenz in Favoriten, History & Views.
//  Warum? Klare Entkopplung von API‑Schemas; zentrale Definition.
//  Testbarkeit: Codable + Equatable → leicht in UnitTests prüfbar.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: Video mit ID, Titel, Beschreibung, Thumbnail‑URL, YouTube‑URL & Kategorie.

// MARK: - Video
/// Repräsentiert ein Video mit Metadaten & Favoriten‑Flag.
struct Video: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let thumbnailURL: String
    /// Hinweis: Erwartet bevorzugt die **YouTube-Video-ID** (z. B. "dQw4w9WgXcQ").
    /// Alternativ kann auch eine vollständige Embed-URL verwendet werden ("https://www.youtube.com/embed/<ID>").
    /// Falls eine "watch?v="- oder "youtu.be/"-URL vorliegt, sollte daraus vor dem Speichern die reine ID extrahiert werden.
    let videoURL: String
    let category: String
    var isFavorite: Bool = false
}

// MARK: - Helpers
extension Video {
    /// Extrahiert eine YouTube‑Video‑ID aus verschiedenen Eingabeformaten.
    /// - Unterstützt: watch?v=ID, youtu.be/ID, nackte ID.
    /// - Fallback: Gibt den Original‑String zurück.
    /// Warum: Vereinheitlicht die Speicherung & Weiterverarbeitung.
    static func extractVideoID(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        if let u = URL(string: trimmed) {
            if let host = u.host, host.contains("youtube.com"),
               let comps = URLComponents(url: u, resolvingAgainstBaseURL: false),
               let v = comps.queryItems?.first(where: { $0.name == "v" })?.value,
               !v.isEmpty {
                return v
            }
            if let host = u.host, host.contains("youtu.be") {
                let id = u.lastPathComponent
                if !id.isEmpty { return id }
            }
        }
        // Fallback: vermutlich ist already eine ID
        return trimmed
    }
}

// MARK: - Sample Data
/// Beispielvideos für Previews & Tests.
let sampleVideos: [Video] = [
    Video(
        id: UUID(),
        title: "Die Kraft der Achtsamkeit",
        description: "Ein inspirierendes Video über Achtsamkeit im Alltag.",
        thumbnailURL: "https://example.com/thumbnail1.jpg",
        videoURL: "xyz",
        category: "Achtsamkeit"
    ),
    Video(
        id: UUID(),
        title: "Mentale Stärke entwickeln",
        description: "Tipps und Übungen für mehr mentale Widerstandskraft.",
        thumbnailURL: "https://example.com/thumbnail2.jpg",
        videoURL: "abc",
        category: "Motivation"
    )
]
