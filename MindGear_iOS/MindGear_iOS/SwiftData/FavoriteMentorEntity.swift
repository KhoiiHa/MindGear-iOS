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

    init(id: String, name: String, profileImageURL: String) {
        self.id = id
        self.name = name
        self.profileImageURL = profileImageURL
    }
}
