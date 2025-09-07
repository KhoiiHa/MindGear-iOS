//
//  RemotePlaylistMapper.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 06.09.25.
//

import Foundation

// Hilfsfunktionen zum Abbilden von Playlist-Caches
extension RemotePlaylistsCache.PlaylistMeta {
    var bestThumb: String? {
        thumbnails?.high ?? thumbnails?.medium ?? thumbnails?.`default`
    }
}

struct RemotePlaylistPreview {
    let id: String
    let title: String
    let thumbnailURL: String?
    let mentor: String?
}

extension Array where Element == RemotePlaylistsCache.PlaylistMeta {
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
