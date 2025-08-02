//
//  YouTubeVideoItem+Mapper.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 02.08.25.
//

import Foundation

extension YouTubeVideoItem {
    func toVideo(category: String) -> Video? {
        guard
            let snippet = snippet,
            let videoId = snippet.resourceId?.videoId,
            let title = snippet.title,
            let description = snippet.description,
            let thumbnailURL = snippet.thumbnails?.high?.url,
            !title.lowercased().contains("private"),
            !description.lowercased().contains("this video is private")
        else {
            return nil
        }

        return Video(
            id: UUID(),
            title: title,
            description: description,
            thumbnailURL: thumbnailURL,
            videoURL: "https://www.youtube.com/watch?v=\(videoId)",
            category: category
        )
    }
}
