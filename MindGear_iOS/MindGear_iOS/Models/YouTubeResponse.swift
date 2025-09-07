//
//  YouTubeResponse.swift
//  MindGear_iOS
//
//  Zweck: API‑Response‑Modelle für YouTube Data API (PlaylistItems & Search).
//  Architekturrolle: Model (Codable/Decodable, API‑Schema‑nah).
//  Verantwortung: Entspricht dem JSON‑Schema der YouTube API.
//  Warum? Saubere Trennung: Netzwerk‑Layer mappt auf diese Modelle → App‑Modelle/Mapper bauen darauf auf.
//  Testbarkeit: Deterministisch; leicht mit Beispiel‑JSON in UnitTests prüfbar.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: PlaylistItems + Search API‑Schema → Decodable Strukturen.

// MARK: - PlaylistItems API
/// Response‑Schema der YouTube PlaylistItems API.
struct YouTubeResponse: Decodable {
    // Token für die nächste Seite (Pagination). Optional, wenn keine weiteren Ergebnisse vorhanden sind.
    let nextPageToken: String?
    let items: [YouTubeVideoItem]
}

struct YouTubeVideoItem: Decodable {
    let snippet: Snippet?
}

struct Snippet: Decodable {
    let title: String?
    let description: String?
    let thumbnails: Thumbnails?
    let resourceId: ResourceID?
}

struct ResourceID: Decodable {
    let videoId: String?
}

struct Thumbnails: Decodable {
    let maxres: Thumbnail?
    let standard: Thumbnail?
    let high: Thumbnail?
    let medium: Thumbnail?
    let defaultThumbnail: Thumbnail?

    enum CodingKeys: String, CodingKey {
        case maxres
        case standard
        case high
        case medium
        case defaultThumbnail = "default"
    }
}

struct Thumbnail: Decodable {
    let url: String?
}

// MARK: - Search API
/// Response‑Schema der YouTube Search API (für spätere Features vorbereitet).
struct YouTubeSearchResponse: Decodable {
    let nextPageToken: String?
    let items: [YouTubeSearchVideoItem]
}

struct YouTubeSearchVideoItem: Decodable {
    let id: SearchVideoID
    let snippet: Snippet?
}

struct SearchVideoID: Decodable {
    let videoId: String
}
