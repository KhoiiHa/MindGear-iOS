//
//  Video.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import Foundation

struct Video: Identifiable, Codable {
    var id: String   // Eindeutige ID (z. B. YouTube-Video-ID)
    var title: String
    var url: String
    var thumbnail: String  // URL zum Thumbnail-Bild
    var description: String?  // Optionale Beschreibung
    
    init(id: String, title: String, url: String, thumbnail: String, description: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.thumbnail = thumbnail
        self.description = description
    }
}
