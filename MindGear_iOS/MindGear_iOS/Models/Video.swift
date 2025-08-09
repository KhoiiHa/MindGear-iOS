//
//  Video.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//


import Foundation

/// Diese Struktur repräsentiert ein Video mit allen relevanten Eigenschaften.
/// Sie ist Identifiable für eindeutige Identifikation, Hashable für die Verwendung in Sets oder als Dictionary-Schlüssel,
/// und Codable, um einfache Kodierung und Dekodierung für Speicherung oder Netzwerkübertragungen zu ermöglichen.
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

extension Video {
    /// Extrahiert die YouTube-Video-ID aus verschiedenen URL-Formaten.
    /// - Akzeptiert: Voll-URL (https://www.youtube.com/watch?v=ID), Kurz-URL (https://youtu.be/ID) oder bereits nackte ID.
    /// - Gibt: Die erkannte Video-ID zurück; bei Nicht-Erkennung den Original-String.
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
