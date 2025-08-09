//
//  YouTubeResponse.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 18.07.25.
//

import Foundation

// MARK: - PlaylistItems API

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
    let high: Thumbnail?
    let medium: Thumbnail?
    let defaultThumbnail: Thumbnail?

    enum CodingKeys: String, CodingKey {
        case high
        case medium
        case defaultThumbnail = "default"
    }
}

struct Thumbnail: Decodable {
    let url: String?
}

// MARK: - Search API (für spätere Features)

struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeSearchVideoItem]
}

struct YouTubeSearchVideoItem: Decodable {
    let id: SearchVideoID
    let snippet: Snippet?
}

struct SearchVideoID: Decodable {
    let videoId: String
}
