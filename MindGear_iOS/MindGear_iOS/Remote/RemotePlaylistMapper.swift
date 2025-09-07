//
//  RemotePlaylistMapper.swift
//  MindGear_iOS
//
//  Zweck: Mapper von Remote‑Playlist‑Meta → kompakte Preview‑Modelle.
//  Architekturrolle: Extension + Adapter‑Struct.
//  Verantwortung: Thumbnail‑Fallback, schlanke Preview‑Struktur für UI.
//  Warum? Trennt Remote‑Schema von UI‑Previews; Views nutzen nur `RemotePlaylistPreview`.
//  Testbarkeit: Deterministisch; mit Mock‑Caches einfach prüfbar.
//  Status: stabil.
//

import Foundation

// Kurzzusammenfassung: Nimmt RemotePlaylistsCache.PlaylistMeta → mappt robust zu Preview (id, title, thumb, mentor).

// MARK: - PlaylistMeta Mapper
/// Liefert abgeleitete Properties (z. B. bestThumb) aus PlaylistMeta.
extension RemotePlaylistsCache.PlaylistMeta {
    var bestThumb: String? {
        thumbnails?.high ?? thumbnails?.medium ?? thumbnails?.`default`
    }
}

// MARK: - RemotePlaylistPreview
/// Kompakte Struktur für die UI (id, title, thumb, mentor).
struct RemotePlaylistPreview {
    let id: String
    let title: String
    let thumbnailURL: String?
    let mentor: String?
}

// MARK: - Array Mapper
/// Konvertiert eine Liste von PlaylistMeta in Previews.
extension Array where Element == RemotePlaylistsCache.PlaylistMeta {
    /// Mappt alle PlaylistMeta auf Preview.
    /// - Returns: Gefilterte Previews mit ID, Titel, Thumb, Mentor.
    /// Warum: Schlanke Schnittstelle für UI‑Listen.
    func mapToPreviews() -> [RemotePlaylistPreview] {
        self.map { m in
            RemotePlaylistPreview(
                id: m.id,
                title: m.title,
                thumbnailURL: m.bestThumb,
                mentor: m.mentor
            )
        }
    }
}
