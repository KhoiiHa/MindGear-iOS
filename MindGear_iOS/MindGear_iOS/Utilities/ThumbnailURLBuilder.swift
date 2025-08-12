//
//  ThumbnailURLBuilder.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

import Foundation

enum ThumbnailQuality: String {
    case max = "maxresdefault"
    case high = "hqdefault"
    case medium = "mqdefault"
    case low = "sddefault"
}

enum ThumbnailURLBuilder {
    static func build(from raw: String, prefer quality: ThumbnailQuality = .high) -> String {
        if raw.lowercased().hasPrefix("http") { return sanitize(raw) }
        
        let id = Video.extractVideoID(from: raw)
        guard !id.isEmpty else { return raw }
        
        return "https://i.ytimg.com/vi/\(id)/\(quality.rawValue).jpg"
    }

    static func sanitize(_ urlString: String) -> String {
        guard var comps = URLComponents(string: urlString) else { return urlString }
        comps.queryItems = (comps.queryItems ?? []).filter { $0.name.lowercased() != "t" }
        return comps.url?.absoluteString ?? urlString
    }
}
