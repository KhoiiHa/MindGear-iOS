//
//  RemoteCacheService.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 06.09.25.
//

import Foundation

// Lädt vorab gespeicherte JSON-Caches von GitHub
struct RemotePlaylistsCache: Codable {
    let fetchedAt: String
    let playlists: [PlaylistMeta]
    struct PlaylistMeta: Codable {
        let id: String
        let title: String
        let description: String
        let channelTitle: String?
        let thumbnails: Thumbs?
        let mentor: String?
        struct Thumbs: Codable { let `default`: String?; let medium: String?; let high: String? }
    }
}

struct RemoteVideosCache: Codable {
    let playlistId: String
    let fetchedAt: String
    let count: Int
    let videos: [VideoItem]
    struct VideoItem: Codable {
        let id: String?
        let title: String
        let description: String
        let publishedAt: String?
        let position: Int?
        let channelTitle: String?
        let thumbnails: Thumbs?
        struct Thumbs: Codable { let `default`: String?; let medium: String?; let high: String? }
    }
}

enum RemoteCacheService {
    // Passe owner/repo/branch bei Bedarf an
    private static let owner = "KhoiiHa"
    private static let repo  = "MindGear-iOS"
    private static let branch = "main"

    private static func base() -> String { "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/data" }
    static func playlistsURL() -> URL { URL(string: "\(base())/playlists.json")! }
    static func videosURL(playlistId: String) -> URL { URL(string: "\(base())/videos_\(playlistId).json")! }

    // MARK: - Loading
    static func loadPlaylists() async throws -> RemotePlaylistsCache {
        let (d,r) = try await URLSession.shared.data(from: playlistsURL())
        guard let h = r as? HTTPURLResponse, (200..<300).contains(h.statusCode) else { throw AppError.networkError }
        return try JSONDecoder().decode(RemotePlaylistsCache.self, from: d)
    }

    static func loadVideos(playlistId: String) async throws -> RemoteVideosCache {
        let (d,r) = try await URLSession.shared.data(from: videosURL(playlistId: playlistId))
        guard let h = r as? HTTPURLResponse, (200..<300).contains(h.statusCode) else { throw AppError.networkError }
        return try JSONDecoder().decode(RemoteVideosCache.self, from: d)
    }
}
