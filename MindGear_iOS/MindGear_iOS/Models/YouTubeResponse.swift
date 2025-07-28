//
//  YouTubeResponse.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 18.07.25.
//



import Foundation

struct YouTubeResponse: Decodable {
    let items: [YouTubeVideoItem]
}

struct YouTubeVideoItem: Decodable {
    let snippet: Snippet
}

struct Snippet: Decodable {
    let title: String
    let description: String
    let thumbnails: Thumbnails
    let resourceId: ResourceID
}

struct ResourceID: Decodable {
    let videoId: String
}

struct Thumbnails: Decodable {
    let medium: Thumbnail
}

struct Thumbnail: Decodable {
    let url: String
}
