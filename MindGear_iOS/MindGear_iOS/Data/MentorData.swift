//
//  MentorData.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//



import Foundation

let allMentors: [Mentor] = [
    Mentor(
        name: "ChrisWillx",
        profileImageURL: "https://yt3.ggpht.com/ytc/AAUvwngZDf_example.jpg",
        bio: "ChrisWillx ist bekannt für seine MEN Series und Mindset-Analysen.",
        channelId: "UC12345...", // Deine echte Channel-ID hier einsetzen
        playlists: nil, // Optional: [PlaylistInfo]
        socials: [
            SocialLink(platform: "YouTube", url: "https://youtube.com/@ChrisWillx")
        ]
    )
    // Weitere Mentoren kannst du später ergänzen
]

/// Resolve a mentor by exact name
func getMentor(byName name: String) -> Mentor? {
    return allMentors.first { $0.name == name }
}

/// Resolve a mentor by YouTube channelId
func getMentor(byChannelId channelId: String) -> Mentor? {
    return allMentors.first { $0.channelId == channelId }
}
