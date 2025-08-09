//
//  PlaylistInfo.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.08.25.
//

import Foundation

/// Diese Struktur repräsentiert die grundlegenden Informationen einer Playlist,
/// einschließlich Titel, Untertitel, Icon und einer eindeutigen ID.
/// Sie ist identifizierbar, hashbar und codierbar, um Vergleiche, Speicherung in Sets
/// sowie Kodierung und Dekodierung für Persistenz oder Netzwerkoperationen zu ermöglichen.
struct PlaylistInfo: Identifiable, Hashable, Codable {
    var id: String { playlistID } // Für ForEach
    let title: String
    let subtitle: String
    let iconName: String
    let playlistID: String
}
