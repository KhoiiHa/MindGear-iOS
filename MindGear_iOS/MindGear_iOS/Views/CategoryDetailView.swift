//
//  CategoryDetailView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 06.08.25.
//


import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    let category: Category
    let modelContext: ModelContext

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(category.icon)
                    .font(.system(size: 72))
                Text(category.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Hier findest du passende Playlists und Impulse für die Kategorie \"\(category.name)\". (Beschreibung kann später angepasst werden)")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)

                Divider()

                // Playlists je nach Kategorie
                switch category.name {
                case "Mindset":
                    PlaylistView(playlistId: ConfigManager.recommendedPlaylistId, context: modelContext)
                case "Disziplin & Fokus":
                    PlaylistView(playlistId: ConfigManager.shawnRyanPlaylistId, context: modelContext)
                case "Emotionale Intelligenz":
                    PlaylistView(playlistId: ConfigManager.jayShettyPlaylistId, context: modelContext)
                case "Beziehungen":
                    PlaylistView(playlistId: ConfigManager.simonSinekPlaylistId, context: modelContext)
                case "Innere Ruhe & Achtsamkeit":
                    PlaylistView(playlistId: ConfigManager.shiHengYiPlaylistId, context: modelContext)
                case "Motivation & Energie":
                    PlaylistView(playlistId: ConfigManager.diaryOfACeoPlaylistId, context: modelContext)
                case "Werte & Purpose":
                    PlaylistView(playlistId: ConfigManager.jordanBPetersonPlaylistId, context: modelContext)
                case "Impulse & Perspektiven":
                    PlaylistView(playlistId: ConfigManager.theoVonPlaylistId, context: modelContext)
                default:
                    Text("📦 Noch keine Playlist verknüpft.")
                        .foregroundColor(.secondary)
                        .padding(.top, 32)
                }
            }
            .padding()
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
