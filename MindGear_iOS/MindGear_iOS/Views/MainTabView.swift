//
//  MainTabView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//


import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            VideoListView(context: context)
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Videos")
                }

            FavoritenView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favoriten")
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
        let container = try! ModelContainer(for: FavoriteVideoEntity.self)
        MainTabView()
            .modelContainer(container)
    }
}
