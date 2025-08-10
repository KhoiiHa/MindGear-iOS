//
//  MentorViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import Foundation
import SwiftData

@MainActor
class MentorViewModel: ObservableObject {
    @Published var mentor: Mentor
    /// Gibt an, ob der Mentor als Favorit markiert ist.
    @Published var isFavorite: Bool = false
    
    private let favoritesManager = FavoritesManager.shared

    init(mentor: Mentor) {
        self.mentor = mentor
    }

    // Beispiel für weitere Methoden:
    // func loadMentorDetails() async { ... }

    /// Synchronisiert den aktuellen Favoritenstatus aus der Persistenz.
    @MainActor
    func syncFavorite(context: ModelContext) {
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }

    /// Wechselt den Favoritenstatus und speichert ihn persistent.
    @MainActor
    func toggleFavorite(context: ModelContext) async {
        await favoritesManager.toggleMentorFavorite(mentor: mentor, context: context)
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }
}
