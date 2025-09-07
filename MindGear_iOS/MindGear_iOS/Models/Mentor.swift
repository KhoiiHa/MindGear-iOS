//
//  Mentor.swift
//  MindGear_iOS
//
//  Zweck: Datenmodell für Mentoren inkl. Channel‑ID, Bio, Playlists & Social‑Links.
//  Architekturrolle: Model (Codable, Hashable, Identifiable).
//  Verantwortung: Einheitliche Struktur für API/Seeds; Referenz in Favoriten & Views.
//  Warum? Klare Entkopplung von API‑Schemas; zentrale Definition.
//  Testbarkeit: Codable + Equatable → leicht in UnitTests verwendbar.
//  Status: stabil.
//

import Foundation

// Kurzzusammenfassung: Mentor mit ID, Name, optionalem Bild/Bio, Playlists & Social‑Links.

// MARK: - Mentor
/// Repräsentiert einen Mentor mit Metadaten & Social‑Links.
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

// MARK: - SocialLink
/// Ein Social‑Media‑Link eines Mentors (z. B. YouTube, Instagram).
struct SocialLink: Identifiable, Hashable, Codable {
    let id = UUID()
    let platform: String // z. B. "YouTube", "Instagram" etc.
    let url: String
    
    private enum CodingKeys: String, CodingKey { case platform, url }
}
