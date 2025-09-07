//
//  MentorData.swift
//  MindGear_iOS
//
//  Zweck: Statische Seed‑Daten für Mentoren (Fallback bei API‑Fehlern oder im Onboarding).
//  Architekturrolle: Data Seed (UI‑nah, aber ohne Logik).
//  Verantwortung: Liste bekannter Mentoren mit ID, Namen, Platzhalter‑Bild, Bio & Social‑Links.
//  Warum? Einheitliche UX auch ohne Netz/YouTube API; klare Struktur; kein doppelter String‑Einsatz in Views.
//  Testbarkeit: Deterministisch; Seeds können leicht in UnitTests geprüft werden.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: 10 Kern‑Mentoren mit Channel‑IDs, Seed‑Bio & Fallback‑Avatar – als sichere Datenquelle.

// MARK: - MentorData (Seeds)
/// Enthält feste Seed‑Daten & Resolver für Mentoren.
enum MentorData {
    static let allMentors: [Mentor] = [
        Mentor(
            id: "UCIaH-gZIVC432YRjNVvnyCA", // Channel‑ID → Chris Williamson (Modern Wisdom)
            name: "[Seed] Chris Williamson",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Host von Modern Wisdom.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@ChrisWillx")
            ]
        ),
        Mentor(
            id: "UCRRtZjnxd5N6Vvq-jU9uoOw", // Channel‑ID → Shi Heng Yi (Shaolin)
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
            id: "UCSHZKyawb77ixDdsGog4iWA", // Channel‑ID → Lex Fridman
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
            id: "UCbV60AGIHKz2xIGvbk0LLvg", // Channel‑ID → Jay Shetty
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
            id: "UCL_f53ZEJxp8TtlOkHwMV9Q", // Channel‑ID → Jordan B. Peterson
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
            id: "UCPmfPl-BsCd3wmE8i45LAoA", // Channel‑ID → Simon Sinek
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
            id: "UCkoujZQZatbqy4KGcgjpVxQ", // Channel‑ID → The Shawn Ryan Show
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
            id: "UCGq-a57w-aPwyi3pW7XLiHw", // Channel‑ID → The Diary of a CEO
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
            id: "UClHVl2N3jPEbkNJVx-ItQIQ", // Channel‑ID → HealthyGamerGG
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
            id: "UC5AQEUAwCh1sGDvkQtkDWUQ", // Channel‑ID → Theo Von
            name: "[Seed] Theo Von",
            profileImageURL: "https://via.placeholder.com/800x800.png?text=Seed+Mentor",
            bio: "Fallback-Daten: Comedy, Podcasts & Lebensgeschichten.",
            playlists: nil,
            socials: [
                SocialLink(platform: "YouTube", url: "https://www.youtube.com/@TheoVon")
            ]
        )
    ]

    /// Sucht Mentor per exaktem Namen.
    /// Warum: Praktisch für Tests/Lookups aus statischen Strings.
    static func getMentor(byName name: String) -> Mentor? {
        return allMentors.first { $0.name == name }
    }

    /// Sucht Mentor per YouTube‑Channel‑ID.
    /// Warum: Stabile Identifikation, da IDs unveränderlich sind.
    static func getMentor(byChannelId channelId: String) -> Mentor? {
        return allMentors.first { $0.id == channelId }
    }
}
