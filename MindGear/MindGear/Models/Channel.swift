//
//  Channel.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import Foundation

struct Channel: Identifiable, Codable {
    var id: String   // Eindeutige ID (z. B. YouTube-Kanal-ID)
    var name: String
    var description: String
    var videos: [Video]  // Liste der zugehörigen Videos
    
    init(id: String, name: String, description: String, videos: [Video] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.videos = videos
    }
}
