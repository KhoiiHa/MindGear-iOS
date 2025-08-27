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
    @Published var mentor: Mentor?
    /// Liste aller Mentoren für die MentorsView
    @Published var mentors: [Mentor] = []
    /// Gibt an, ob der Mentor als Favorit markiert ist.
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    let context: ModelContext?
    
    private let favoritesManager = FavoritesManager.shared
    private var favoritesObserver: NSObjectProtocol?

    init(mentor: Mentor? = nil, context: ModelContext? = nil) {
        self.mentor = mentor
        self.context = context
    }

    /// Startet einen Listener auf Favoriten-Änderungen und hält den Status synchron.
    func startObservingFavorites() {
        guard mentor != nil, context != nil else { return }
        // Erstes Sync beim Start
        syncFavorite()
        // Notification-Listener (auf dem Main-Thread)
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard self?.mentor != nil, self?.context != nil else { return }
                self?.syncFavorite()
            }
        }
    }

    /// Gibt an, ob der Mentor als Favorit markiert ist.
    func syncFavorite() {
        guard let mentor = mentor, let context = context else { return }
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }

    /// Wechselt den Favoritenstatus und speichert ihn persistent.
    func toggleFavorite() async {
        guard let mentor = mentor, let context = context else { return }
        await favoritesManager.toggleMentorFavorite(mentor: mentor, context: context)
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }
    
    // MARK: - Helpers
    private func handleFromSocials(for m: Mentor) -> String? {
        guard let socials = m.socials else { return nil }
        for s in socials where s.platform.lowercased() == "youtube" {
            if let range = s.url.range(of: "/@") {
                let raw = String(s.url[range.upperBound...]) // e.g. "lexfridman" or "lexfridman/videos"
                return raw.split(separator: "/").first.map(String.init)
            }
        }
        return nil
    }

    private func handleFromSocials() -> String? { guard let mentor = mentor else { return nil }; return handleFromSocials(for: mentor) }

    /// Lädt echte Mentor-Daten aus der YouTube API (falls verfügbar)
    func loadFromAPIIfPossible() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard var base = mentor else { return }

        let key = ConfigManager.resolvedYouTubeAPIKey
        guard !key.isEmpty else {
            #if DEBUG
            print("⚠️ Kein API-Key gefunden – Seeds bleiben aktiv.")
            #endif
            return
        }

        do {
            let updated = try await NetworkManager.shared.loadMentor(
                preferId: base.id.isEmpty ? nil : base.id,
                handle: handleFromSocials(),
                apiKey: key
            )

            // Felder idempotent & defensiv mergen (Seeds nur ergänzen, keine leeren Werte übernehmen)
            if !updated.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                base.name = updated.name
            }
            // Prefer API profile image if available
            if let url = updated.profileImageURL, !url.isEmpty {
                base.profileImageURL = url
            }
            // Prefer API bio if available and longer or not empty
            let newBio = (updated.bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let oldBio = (base.bio ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !newBio.isEmpty, (oldBio.isEmpty || newBio.count > oldBio.count) {
                base.bio = newBio
            }
            if (base.socials == nil || base.socials?.isEmpty == true), let socials = updated.socials, !socials.isEmpty {
                base.socials = socials
            }
            self.mentor = base
        } catch {
            #if DEBUG
            print("ℹ️ Mentor-API-Fallback aktiv:", error.localizedDescription)
            #endif
            errorMessage = nil // Seeds behalten, UI ruhig lassen
        }
    }

    /// Lädt alle Mentoren (API-first, Seeds als Fallback)
    func loadAllMentors(seeds: [Mentor]) async {
        isLoading = true
        errorMessage = nil
        var loaded: [Mentor] = []
        loaded.reserveCapacity(seeds.count)
        let key = ConfigManager.resolvedYouTubeAPIKey
        for seed in seeds {
            if Task.isCancelled { break }
            do {
                if !key.isEmpty {
                    let handle = handleFromSocials(for: seed)
                    let m = try await NetworkManager.shared.loadMentor(
                        preferId: seed.id.isEmpty ? nil : seed.id,
                        handle: handle,
                        apiKey: key
                    )
                    loaded.append(m)
                } else {
                    loaded.append(seed)
                }
            } catch {
                loaded.append(seed)
            }
        }
        await MainActor.run {
            self.mentors = loaded
            self.isLoading = false
        }
    }

    deinit {
        if let obs = favoritesObserver { NotificationCenter.default.removeObserver(obs) }
    }
}
