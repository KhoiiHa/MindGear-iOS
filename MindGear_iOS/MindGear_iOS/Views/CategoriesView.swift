//
//  CategoriesView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List(categories) { category in
                NavigationLink {
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
                        Text("📦 Noch keine Playlist verknüpft")
                    }
                } label: {
                    HStack {
                        Text(category.icon)
                            .font(.largeTitle)
                        Text(category.name)
                            .font(.headline)
                            .padding(.leading, 8)
                    }
                }
            }
            .navigationTitle("Kategorien")
        }
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesView()
    }
}
