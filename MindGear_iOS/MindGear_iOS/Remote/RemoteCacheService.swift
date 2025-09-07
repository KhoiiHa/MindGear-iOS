//
//  RemoteCacheService.swift
//  MindGear_iOS
//
//  Zweck: Zugriff auf vorab gespeicherte JSON‑Caches (Playlists/Videos) von GitHub.
//  Architekturrolle: Remote‑Service (API‑ähnlich, aber statisch).
//  Verantwortung: URLs bauen, Caches laden & decodieren.
//  Warum? Offline‑/API‑Fallback, schnellere Tests, deterministische Daten.
//  Testbarkeit: Deterministisch via Mock‑JSON; async/throws für sauberes Error‑Handling.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: Lädt Caches (playlists.json, videos_*.json) direkt aus GitHub raw‑content.

// MARK: - RemotePlaylistsCache
/// Struktur eines Playlist‑Caches (fetchedAt + Playlists + Thumbnails).
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

// MARK: - RemoteVideosCache
/// Struktur eines Video‑Caches (playlistId + Videos + Thumbnails).
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

// MARK: - RemoteCacheService
/// Baut URLs & lädt JSON‑Caches; dient als statischer Remote‑Service.
enum RemoteCacheService {
    // GitHub‑Repo‑Quelle → anpassbar (Owner/Repo/Branch)
    private static let owner = "KhoiiHa"
    private static let repo  = "MindGear-iOS"
    private static let branch = "main"

    // Basis‑URL für raw.githubusercontent
    private static func base() -> String { "https://raw.githubusercontent.com/\(owner)/\(repo)/\(branch)/data" }
    // URL zum Playlist‑Cache
    static func playlistsURL() -> URL { URL(string: "\(base())/playlists.json")! }
    // URL zum Video‑Cache je Playlist
    static func videosURL(playlistId: String) -> URL { URL(string: "\(base())/videos_\(playlistId).json")! }

    /// Lädt & decodiert den Playlist‑Cache.
    /// - Throws: AppError bei HTTP‑Fehler; Decoding‑Fehler sonst.
    static func loadPlaylists() async throws -> RemotePlaylistsCache {
        let (data, response) = try await URLSession.shared.data(from: playlistsURL())
        guard let http = response as? HTTPURLResponse else { throw AppError.invalidResponse }

        switch http.statusCode {
        case 200: break
        case 401,403: throw AppError.unauthorized
        case 404: throw AppError.httpStatus(404)
        case 429:
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw AppError.rateLimited(retryAfter: retry)
        case 500...599: throw AppError.httpStatus(http.statusCode)
        default: throw AppError.httpStatus(http.statusCode)
        }

        guard !data.isEmpty else { throw AppError.noData }

        do {
            return try JSONDecoder().decode(RemotePlaylistsCache.self, from: data)
        } catch {
            throw AppError.from(error)
        }
    }

    /// Lädt & decodiert den Video‑Cache für eine Playlist.
    /// - Parameter playlistId: ID der Playlist.
    /// - Throws: AppError bei HTTP‑Fehler; Decoding‑Fehler sonst.
    static func loadVideos(playlistId: String) async throws -> RemoteVideosCache {
        let (data, response) = try await URLSession.shared.data(from: videosURL(playlistId: playlistId))
        guard let http = response as? HTTPURLResponse else { throw AppError.invalidResponse }

        switch http.statusCode {
        case 200: break
        case 401,403: throw AppError.unauthorized
        case 404: throw AppError.httpStatus(404)
        case 429:
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw AppError.rateLimited(retryAfter: retry)
        case 500...599: throw AppError.httpStatus(http.statusCode)
        default: throw AppError.httpStatus(http.statusCode)
        }

        guard !data.isEmpty else { throw AppError.noData }

        do {
            return try JSONDecoder().decode(RemoteVideosCache.self, from: data)
        } catch {
            throw AppError.from(error)
        }
    }
}
