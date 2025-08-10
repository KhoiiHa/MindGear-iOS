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
    let context: ModelContext
    
    private let favoritesManager = FavoritesManager.shared
    private var favoritesObserver: NSObjectProtocol?

    init(mentor: Mentor, context: ModelContext) {
        self.mentor = mentor
        self.context = context
    }

    /// Startet einen Listener auf Favoriten-Änderungen und hält den Status synchron.
    func startObservingFavorites() {
        // Erstes Sync beim Start
        syncFavorite()
        // Notification-Listener (auf dem Main-Thread)
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.syncFavorite()
            }
        }
    }

    /// Gibt an, ob der Mentor als Favorit markiert ist.
    func syncFavorite() {
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }

    /// Wechselt den Favoritenstatus und speichert ihn persistent.
    func toggleFavorite() async {
        await favoritesManager.toggleMentorFavorite(mentor: mentor, context: context)
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }
    
    deinit {
        if let obs = favoritesObserver { NotificationCenter.default.removeObserver(obs) }
    }
}
