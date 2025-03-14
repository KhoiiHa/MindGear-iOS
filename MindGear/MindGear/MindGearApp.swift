//
//  MindGearApp.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import SwiftUI
import SwiftData

@main
struct MindGearApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // Beispiel-Daten für die Channels
    let channels = [
        Channel(id: "1", name: "Joe Rogan", description: "Ein bekannter Podcast über eine Vielzahl von Themen."),
        Channel(id: "2", name: "Chris Williamson", description: "Podcast über Persönlichkeitsentwicklung und Selbstverbesserung.")
    ]
    
    var body: some Scene {
        WindowGroup {
            HomeView(channels: channels)  // channels an HomeView übergeben
        }
        .modelContainer(sharedModelContainer)
    }
}
