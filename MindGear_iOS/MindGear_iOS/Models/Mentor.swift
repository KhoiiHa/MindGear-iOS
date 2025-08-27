//
//  Mentor.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import Foundation

// Repräsentiert einen Mentor mit Kanal- und Social-Media-Informationen
struct Mentor: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var profileImageURL: String?
    var bio: String?
    let playlists: [PlaylistInfo]?
    var socials: [SocialLink]?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, profileImageURL, bio, playlists, socials
    }
}

// Repräsentiert einen Social-Media-Link eines Mentors
struct SocialLink: Identifiable, Hashable, Codable {
    let id = UUID()
    let platform: String // z. B. "YouTube", "Instagram" etc.
    let url: String
    
    private enum CodingKeys: String, CodingKey { case platform, url }
}
