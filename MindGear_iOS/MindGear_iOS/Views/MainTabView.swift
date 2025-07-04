//
//  MainTabView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            VideoListView()
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Videos")
                }

            FavoritenView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favoriten")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
