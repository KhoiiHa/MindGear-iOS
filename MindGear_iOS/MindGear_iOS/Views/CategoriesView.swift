//
//  CategoriesView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 29.07.25.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            List(categories) { category in
                NavigationLink {
                    switch category.name {
                    case "Emotionale Intelligenz":
                        PlaylistView(playlistId: ConfigManager.jayShettyPlaylistId, context: modelContext)
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

struct CategoriesView_Previews {
    #Preview {
        CategoriesView()
    }
}
