//
//  MainTabView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//


import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            VideoListView(playlistID: ConfigManager.recommendedPlaylistId, context: context)
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Videos")
                }

            FavoritenView(context: context)
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favoriten")
                }

            CategoriesView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Kategorien")
                }

            MentorsView(mentors: allMentors)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Mentoren")
                }

            PlaylistView(playlistId: ConfigManager.recommendedPlaylistId, context: context)
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Playlists")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Einstellungen")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self, FavoriteMentorEntity.self)
        MainTabView()
            .modelContainer(container)
    }
}
