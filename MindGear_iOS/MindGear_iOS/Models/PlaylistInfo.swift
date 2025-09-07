//
//  PlaylistInfo.swift
//  MindGear_iOS
//
//  Zweck: Kompaktes Modell für Playlists (Titel, Untertitel, Icon, ID, optionales Thumbnail).
//  Architekturrolle: Model (Codable, Hashable, Identifiable).
//  Verantwortung: Einheitliche Struktur für UI & Remote‑Daten.
//  Warum? Views & ViewModels greifen auf dieselben Properties zu; klare Entkopplung von API.
//  Testbarkeit: Codable + Equatable → leicht in UnitTests prüfbar.
//  Status: stabil.
//

import Foundation

// Kurzzusammenfassung: Playlist mit Titel/Untertitel/Icon/ID + optionalem Thumbnail.

// MARK: - PlaylistInfo
/// Kompaktes Playlist‑Modell; nutzbar für UI‑Listen, Favoriten & Remote‑Mappers.
struct PlaylistInfo: Identifiable, Hashable, Codable {
    var id: String { playlistID } // Für ForEach
    let title: String
    let subtitle: String
    let iconName: String
    let playlistID: String
    let thumbnailURL: String?
}
