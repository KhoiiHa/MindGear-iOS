//
//  HistoryViewModel.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 11.08.25.
//

import Foundation
import SwiftData

/// ViewModel für den Video‑Verlauf ("Zuletzt gesehen").
/// Nutzt SwiftData mit FetchDescriptor/SortDescriptor (ohne async/await).
@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var history: [WatchHistoryEntity] = []

    /// Lädt den Verlauf, sortiert nach `watchedAt` (neueste zuerst).
    func loadHistory(context: ModelContext) {
        let descriptor = FetchDescriptor<WatchHistoryEntity>(
            sortBy: [SortDescriptor(\.watchedAt, order: .reverse)]
        )
        do {
            history = try context.fetch(descriptor)
        } catch {
            print("Failed to load history:", error)
        }
    }

    /// Fügt einen Verlaufseintrag hinzu oder aktualisiert den Zeitstempel, falls bereits vorhanden.
    func addToHistory(videoId: String, title: String, thumbnailURL: String, context: ModelContext) {
        do {
            // Dedup nach videoId
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

    /// Entfernt einen Verlaufseintrag.
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
