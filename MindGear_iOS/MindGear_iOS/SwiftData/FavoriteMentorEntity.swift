//
//  FavoriteMentorEntity.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 10.08.25.
//

import Foundation
import SwiftData

/// SwiftData-Modell für Mentor-Favoriten
/// Hinweis: `id` entspricht der **YouTube-Channel-ID** und ist eindeutig.
@Model
final class FavoriteMentorEntity {
    /// Eindeutiger Schlüssel (YouTube-Channel-ID)
    @Attribute(.unique) var id: String
    /// Anzeigename des Mentors (für die Liste)
    var name: String
    /// Optionales Profilbild (URL-String)
    var profileImageURL: String
    /// Zeitpunkt, wann der Mentor als Favorit gespeichert wurde
    var createdAt: Date
    /// Typ zur Unterscheidung zwischen Video- und Mentor-Favoriten
    var type: String = "mentor"

    init(id: String, name: String, profileImageURL: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.type = "mentor"
    }
}
