//
//  HistoryViewModel.swift
//  MindGear_iOS
//
//  Zweck: UI‑Zustand & Logik für den Video‑Verlauf („Zuletzt gesehen“).
//  Architekturrolle: ViewModel (MVVM).
//  Verantwortung: Laden, Hinzufügen, Aktualisieren, Löschen von Verlaufseinträgen.
//  Warum? Entkoppelt Views von Persistenz‑Details; konsistente Anzeige und deterministische Tests.
//  Testbarkeit: SwiftData‑Context injizierbar; State‑Updates klar prüfbar.
//  Status: stabil.
//

import Foundation
import SwiftData

// Kurzzusammenfassung: Nutzt SwiftData (FetchDescriptor/SortDescriptor) für deterministisches Laden, hält State via @Published.

// MARK: - Implementierung: HistoryViewModel
// Warum: Zentralisiert Verlauf‑State; erleichtert UI‑Tests und Wiederverwendung.
@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - State
    // Enthält WatchHistoryEntities, sortiert nach watchedAt (neueste zuerst).
    @Published var history: [WatchHistoryEntity] = []

    // MARK: - Loading
    /// Lädt den Verlauf (WatchHistoryEntity), sortiert nach `watchedAt` absteigend.
    /// Warum: UI braucht deterministische Reihenfolge für Anzeige & Tests.
    func loadHistory(context: ModelContext) {
        let descriptor = FetchDescriptor<WatchHistoryEntity>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        do {
            // Neueste zuerst → UI bleibt konsistent & testbar
            history = try context.fetch(descriptor)
        } catch {
            print("Failed to load history:", error)
        }
    }

    // MARK: - Actions (Mutations)
    /// Fügt einen Verlaufseintrag hinzu oder aktualisiert den Zeitstempel, falls bereits vorhanden.
    /// Warum: Dedupliziert nach videoId; aktualisiert statt dupliziert – verhindert aufgeblähte History.
    func addToHistory(videoId: String, title: String, thumbnailURL: String, context: ModelContext) {
        do {
            // Dedup nach videoId – bestehender Eintrag wird aktualisiert statt dupliziert.
            let predicate = #Predicate<WatchHistoryEntity> { $0.videoId == videoId }
            let existingDescriptor = FetchDescriptor<WatchHistoryEntity>(predicate: predicate)
            if let existing = try context.fetch(existingDescriptor).first {
                existing.title = title
                existing.thumbnailURL = thumbnailURL
                existing.watchedAt = .now
            } else {
                let entry = WatchHistoryEntity(
                    videoId: videoId,
                    title: title,
                    thumbnailURL: thumbnailURL,
                    watchedAt: .now
                )
                context.insert(entry)
            }
            try context.save()
            loadHistory(context: context)
        } catch {
            print("Failed to add to history:", error)
        }
    }

    // MARK: - Deletion
    /// Entfernt einen Verlaufseintrag.
    /// Warum: UI soll verlässlich konsistent bleiben; State wird nach Save neu geladen.
    func deleteFromHistory(entry: WatchHistoryEntity, context: ModelContext) {
        context.delete(entry)
        do {
            try context.save()
            loadHistory(context: context)
        } catch {
            print("Failed to delete from history:", error)
        }
    }
}
