//
//  RemoteMappers.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 06.09.25.
//

import Foundation

extension RemoteVideosCache.VideoItem {
    /// Wählt die beste Thumbnail-URL (high > medium > default)
    var bestThumb: String? {
        thumbnails?.high ?? thumbnails?.medium ?? thumbnails?.`default`
    }
}

extension Array where Element == RemoteVideosCache.VideoItem {
    func mapToVideos() -> [Video] {
        self.compactMap { (item) -> Video? in
            guard let id = item.id else { return nil }
            let thumb = (item.bestThumb ?? "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")
                .replacingOccurrences(of: "http://", with: "https://")
            return Video(
                id: UUID(),
                title: item.title,
                description: item.description,
                thumbnailURL: thumb,
                videoURL: id,      // wir speichern die reine YouTube-Video-ID
                category: "YouTube"
            )
        }
    }
}
