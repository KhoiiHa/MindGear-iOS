//
//  MentorData.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import Foundation

let allMentors: [Mentor] = [
    Mentor(
        id: "UCIaH-gZIVC432YRjNVvnyCA", // Channel-ID Chris Williamson (Modern Wisdom)
        name: "Chris Williamson",
        profileImageURL: "https://yt3.googleusercontent.com/ytc/AIf8zZQ_example1=s800-c-k-c0x00ffffff-no-rj",
        bio: "Host von Modern Wisdom. Gespräche über Psychologie, Erfolg und Lebensführung.",
        playlists: nil,
        socials: [
            SocialLink(platform: "YouTube", url: "https://www.youtube.com/@ChrisWillx")
        ]
    ),
    Mentor(
        id: "UCRRtZjnxd5N6Vvq-jU9uoOw", // Channel-ID Shi Heng Yi Online
        name: "Shi Heng Yi",
        profileImageURL: "https://yt3.googleusercontent.com/ytc/AIf8zZQ_example2=s800-c-k-c0x00ffffff-no-rj",
        bio: "Shaolin-Lehrer. Fokus auf Disziplin, Achtsamkeit und innere Stärke.",
        playlists: nil,
        socials: [
            SocialLink(platform: "YouTube", url: "https://www.youtube.com/@ShiHengYiOnline")
        ]
    )
]

/// Resolve a mentor by exact name
func getMentor(byName name: String) -> Mentor? {
    return allMentors.first { $0.name == name }
}

/// Resolve a mentor by YouTube channelId
func getMentor(byChannelId channelId: String) -> Mentor? {
    return allMentors.first { $0.id == channelId }
}
