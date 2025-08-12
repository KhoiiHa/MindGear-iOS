//
//  YouTubeVideoItem+Mapper.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 02.08.25.
//

import Foundation

extension YouTubeVideoItem {
    func toVideo(category: String) -> Video? {
        // Defensive Unwrap: snippet + videoId sind Pflicht
        guard let snippet = snippet, let videoId = snippet.resourceId?.videoId else {
            return nil
        }

        // Titel/Beschreibung optional abfedern
        let rawTitle = snippet.title ?? ""
        let rawDescription = snippet.description ?? ""

        // Private/gesperrte Inhalte überspringen (robuster, auch wenn nur Titel vorhanden ist)
        let isPrivateTitle = rawTitle.lowercased().contains("private")
        let isPrivateDesc  = rawDescription.lowercased().contains("this video is private")
        if isPrivateTitle || isPrivateDesc {
            return nil
        }

        // Thumbnail-Auswahl: high -> medium -> default; Fallback zu i.ytimg.com
        let candidateThumb = snippet.thumbnails?.high?.url
            ?? snippet.thumbnails?.medium?.url
            ?? snippet.thumbnails?.defaultThumbnail?.url

        let thumbnailURL = candidateThumb ?? "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg"

        // Build Video-Domain-Objekt (behalte deine aktuellen Felder/Typen bei)
        return Video(
            id: UUID(), // intern verwendete UUID; die eigentliche Video-Id steckt in videoURL
            title: rawTitle.isEmpty ? "Unbenannter Titel" : rawTitle,
            description: rawDescription,
            thumbnailURL: thumbnailURL,
            videoURL: "https://www.youtube.com/watch?v=\(videoId)",
            category: category
        )
    }
}
