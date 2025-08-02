//
//  HomeView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Willkommensbereich
                    VStack(alignment: .leading, spacing: 8) {
                        Text("👋 Willkommen zurück!")
                            .font(.title)
                            .bold()
                        Text("Was möchtest du heute entdecken?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // Empfohlene Kategorie
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎯 Empfohlen")
                            .font(.headline)

                        NavigationLink {
                            VideoListView(
                                playlistID: ConfigManager.recommendedPlaylistId,
                                context: context
                            )
                        } label: {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.yellow)

                                VStack(alignment: .leading) {
                                    Text("Die M.E.N. Series")
                                        .font(.headline)
                                    Text("Playlist von ChrisWillx")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }

                    // Weitere Bereiche (Platzhalter für zukünftige Erweiterung)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🧠 Deine Mindset-Kategorien")
                            .font(.headline)
                        Text("In Kürze verfügbar …")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("🏠 Startseite")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self)
        HomeView()
            .modelContainer(container)
    }
}
