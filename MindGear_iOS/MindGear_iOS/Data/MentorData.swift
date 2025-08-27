//
//  MentorData.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import Foundation

enum MentorData {
    static let allMentors: [Mentor] = [
        Mentor(
            id: "UCIaH-gZIVC432YRjNVvnyCA", // Channel-ID Chris Williamson (Modern Wisdom)
            name: "[Seed] Chris Williamson",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Host von Modern Wisdom.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@ChrisWillx")
            ]
        ),
        Mentor(
            id: "UCRRtZjnxd5N6Vvq-jU9uoOw", // Channel-ID Shi Heng Yi Online
            name: "[Seed] Shi Heng Yi",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Shaolin-Lehrer.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@ShiHengYiOnline")
            ]
        ),
        // Lex Fridman
        Mentor(
            id: "UCSHZKyawb77ixDdsGog4iWA", // Lex Fridman intended handle: lexfridman
            name: "[Seed] Lex Fridman",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: KI, Wissenschaft & Gespräche.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@lexfridman")
            ]
        ),
        // Jay Shetty
        Mentor(
            id: "UCbV60AGIHKz2xIGvbk0LLvg", // Jay Shetty intended handle: JayShetty
            name: "[Seed] Jay Shetty",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Purpose, Motivation & Life Coaching.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@JayShetty")
            ]
        ),
        // Jordan B. Peterson
        Mentor(
            id: "UCL_f53ZEJxp8TtlOkHwMV9Q", // Jordan B. Peterson intended handle: jordanbpeterson
            name: "[Seed] Jordan B. Peterson",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Psychologie, Philosophie & Selbstentwicklung.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@jordanbpeterson")
            ]
        ),
        // Simon Sinek
        Mentor(
            id: "UCPmfPl-BsCd3wmE8i45LAoA", // Simon Sinek intended handle: simonsinek
            name: "[Seed] Simon Sinek",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Leadership, Inspiration & Unternehmertum.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@simonsinek")
            ]
        ),
        // The Shawn Ryan Show
        Mentor(
            id: "UCkoujZQZatbqy4KGcgjpVxQ", // The Shawn Ryan Show intended handle: shawnryanshow
            name: "[Seed] The Shawn Ryan Show",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Militär, Sicherheit & offene Gespräche.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@shawnryanshow")
            ]
        ),
        // The Diary of a CEO
        Mentor(
            id: "UCGq-a57w-aPwyi3pW7XLiHw", // The Diary of a CEO intended handle: TheDiaryOfACEO
            name: "[Seed] The Diary of a CEO",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Unternehmer, Erfolg & persönliche Entwicklung.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@TheDiaryOfACEO")
            ]
        ),
        // HealthyGamerGG
        Mentor(
            id: "UClHVl2N3jPEbkNJVx-ItQIQ", // HealthyGamerGG intended handle: HealthyGamerGG
            name: "[Seed] HealthyGamerGG",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Mental Health, Gaming & Coaching.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@HealthyGamerGG")
            ]
        ),
        // Theo Von
        Mentor(
            id: "UC5AQEUAwCh1sGDvkQtkDWUQ", // Theo Von intended handle: TheoVon
            name: "[Seed] Theo Von",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Comedy, Podcasts & Lebensgeschichten.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@TheoVon")
            ]
        )
    ]

    /// Resolve a mentor by exact name
    static func getMentor(byName name: String) -> Mentor? {
        return allMentors.first { $0.name == name }
    }

    /// Resolve a mentor by YouTube channelId
    static func getMentor(byChannelId channelId: String) -> Mentor? {
        return allMentors.first { $0.id == channelId }
    }
}
