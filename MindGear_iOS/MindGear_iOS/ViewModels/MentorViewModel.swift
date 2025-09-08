//
//  MentorViewModel.swift
//  MindGear_iOS
//
//  Zweck: UI‑Zustand & Logik für Mentoren (Einzelansicht + Liste).
//  Architekturrolle: ViewModel (MVVM).
//  Verantwortung: Laden/Mergen von API‑Daten, Favoriten‑Sync, Suche & Vorschläge.
//  Warum? Entkoppelt Views von Nebenwirkungen; deterministischer UI‑State für Tests.
//  Testbarkeit: Services injizierbar (Network/Config), SwiftData‑Context optional; Observer klar gekapselt.
//  Status: stabil.
//

import Foundation
import SwiftData

// Kurzzusammenfassung: Lädt/merged Mentor‑Daten aus API & Seeds, hält Favoriten‑Status aktuell, bietet Suche & Suggestions.

// MARK: - Implementierung: MentorViewModel
// Warum: Zentralisiert Mentor‑State (Einzel + Liste) und entlastet Views.
@MainActor
class MentorViewModel: ObservableObject {
    // MARK: - State
    @Published var mentor: Mentor?
    /// Liste aller Mentoren für die MentorsView
    @Published var mentors: [Mentor] = []
    /// Gibt an, ob der Mentor als Favorit markiert ist.
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    // Injektionspunkt für Persistenz (optional) – erleichtert Tests & Previews
    let context: ModelContext?
    
    // Services
    private let favoritesManager = FavoritesManager.shared
    // Hält Notification‑Token für Live‑Updates (Favoriten)
    private var favoritesObserver: NSObjectProtocol?

    // MARK: - Init
    init(mentor: Mentor? = nil, context: ModelContext? = nil) {
        self.mentor = mentor
        self.context = context
    }

    // MARK: - Favorites
    /// Startet einen Listener auf Favoriten‑Änderungen und hält den Status synchron.
    /// Warum: UI‑Badges/Toggles bleiben korrekt, ohne manuelle Refresh‑Logik in Views.
    func startObservingFavorites() {
        guard mentor != nil, context != nil else { return }
        // Initial‑Sync: Status einmalig aus Persistenz holen
        syncFavorite()
        // Listener: .favoritesDidChange → Favoritenstatus neu berechnen (Main‑Thread)
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard self?.mentor != nil, self?.context != nil else { return }
                self?.syncFavorite()
            }
        }
    }

    /// Synchronisiert den Favoritenstatus mit der Persistenz.
    /// Warum: Quelle der Wahrheit liegt im FavoritesManager/SwiftData.
    func syncFavorite() {
        guard let mentor = mentor, let context = context else { return }
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }

    /// Wechselt den Favoritenstatus und speichert ihn persistent.
    /// Warum: Kapselt Insert/Delete + anschließendes Re‑Read für konsistenten UI‑State.
    func toggleFavorite() async {
        guard let mentor = mentor, let context = context else { return }
        await favoritesManager.toggleMentorFavorite(mentor: mentor, context: context)
        isFavorite = favoritesManager.isMentorFavorite(mentor: mentor, context: context)
    }
    
    // MARK: - Helpers
    /// Normalisiert Strings für vergleichende Suche (Diakritika + Case‑Folding).
    /// Warum: Einheitliche Treffer auch bei ä/ö/ü oder Groß/Kleinschreibung.
    private func norm(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
    /// Extrahiert YouTube‑Handle aus den Social‑Links des Mentors (falls vorhanden).
    /// Warum: Erlaubt API‑Abfragen auch ohne Channel‑ID (Fallback).
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

    // Bequeme Variante für den aktuell gesetzten Mentor
    private func handleFromSocials() -> String? { guard let mentor = mentor else { return nil }; return handleFromSocials(for: mentor) }

    // MARK: - Loading Single Mentor
    /// Lädt echte Mentor‑Daten aus der YouTube‑API (falls verfügbar) und merged defensiv.
    /// Warum: Seeds bleiben Basis; API‑Daten ergänzen nur nicht‑leere/„bessere“ Felder (idempotent).
    func loadFromAPIIfPossible() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard var base = mentor else { return }

        let key = ConfigManager.resolvedYouTubeAPIKey
        // Ohne API‑Key: Seeds verwenden und still fortfahren (kein UI‑Fehler)
        guard !key.isEmpty else {
            #if DEBUG
            print("⚠️ Kein API-Key gefunden – Seeds bleiben aktiv.")
            #endif
            return
        }

        do {
            // API‑Abruf: bevorzugt Channel‑ID, fällt bei Bedarf auf Handle zurück
            let updated = try await NetworkManager.shared.loadMentor(
                preferId: base.id.isEmpty ? nil : base.id,
                handle: handleFromSocials(),
                apiKey: key
            )

            // Merge: Nur sinnvolle/„bessere“ Werte übernehmen (keine leeren Strings)
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
            let appErr = AppError.from(error)
            #if DEBUG
            print("ℹ️ Mentor-API-Fallback aktiv:", appErr.localizedDescription)
            #endif
            // Seeds bleiben aktiv – nur bei API-Key-Mangel explizite Meldung
            if case .apiKeyMissing = appErr {
                errorMessage = AppErrorPresenter.message(for: appErr)
            } else {
                errorMessage = nil
                if let hint = AppErrorPresenter.hint(for: appErr) {
                    errorMessage = hint
                }
            }
        }
    }

    // MARK: - Loading All Mentors
    /// Lädt alle Mentoren (API‑first, Seeds als Fallback) und baut eine konsistente Liste.
    /// Warum: Robuste UX auch ohne Schlüssel/bei Fehlern; Reihenfolge entspricht Seeds.
    func loadAllMentors(seeds: [Mentor]) async {
        isLoading = true
        errorMessage = nil
        var loaded: [Mentor] = []
        loaded.reserveCapacity(seeds.count)
        let key = ConfigManager.resolvedYouTubeAPIKey
        for seed in seeds {
            if Task.isCancelled { break }
            do {
                // Falls Key vorhanden: API‑Pfad; sonst Seeds übernehmen
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
                let appErr = AppError.from(error)
                #if DEBUG
                print("ℹ️ Mentor-Liste: Seed-Fallback aktiv für \(seed.name):", appErr.localizedDescription)
                #endif
                // Fallback: Seed behalten, damit UI vollständig bleibt
                loaded.append(seed)
                if case .apiKeyMissing = appErr, errorMessage == nil {
                    errorMessage = AppErrorPresenter.message(for: appErr)
                } else if errorMessage == nil, let hint = AppErrorPresenter.hint(for: appErr) {
                    errorMessage = hint
                }
            }
        }
        await MainActor.run {
            self.mentors = loaded
            self.isLoading = false
        }
    }

    // MARK: - Search
    /// Filtert die Mentorenliste nach einem Suchstring in Name & Bio.
    /// Warum: Einfache, performante Client‑Suche ohne zusätzliche API‑Kosten.
    func filteredMentors(query: String) -> [Mentor] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return mentors }
        return mentors.filter { m in
            let name = m.name.lowercased()
            let bio  = (m.bio ?? "").lowercased()
            return name.contains(q) || bio.contains(q)
        }
    }

    // MARK: - Suggestions
    /// Liefert Auto‑Vervollständigungs‑Vorschläge aus Name & Bio.
    /// Warum: Nutzerfreundliche Suche; dedupliziert über normalisierte Keys.
    func suggestions(for query: String, limit: Int = 10) -> [String] {
        let q = norm(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !q.isEmpty else { return [] }
        var seen = Set<String>()
        var result: [String] = []
        for m in mentors {
            let candidates: [String] = [
                m.name,
                m.bio ?? ""
            ]
            for c in candidates {
                guard !c.isEmpty else { continue }
                let key = norm(c)
                if key.contains(q) && !seen.contains(key) {
                    seen.insert(key)
                    result.append(c)
                    if result.count >= limit { return result }
                }
            }
        }
        return result
    }

    // MARK: - Lifecycle
    deinit {
        if let obs = favoritesObserver { NotificationCenter.default.removeObserver(obs) }
    }
}
