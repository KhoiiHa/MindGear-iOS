//
//  Mentor.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import Foundation

struct Mentor: Identifiable {
    let id = UUID()
    let name: String
    let profileImageURL: String  // Profilbild
    let bio: String
    let channelId: String        // Für Kanal-Link & weitere Features
    let playlists: [PlaylistInfo]?
    let socials: [SocialLink]?
}

// Für Social Links (optional)
struct SocialLink: Identifiable {
    let id = UUID()
    let platform: String // z. B. "YouTube", "Instagram"
    let url: String
}
