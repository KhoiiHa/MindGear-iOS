//
//  MainTabView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//


import SwiftUI
import SwiftData
import UIKit

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = .clear
        appearance.shadowColor = UIColor(AppTheme.Colors.separator)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppTheme.Colors.textSecondary)
        UITabBar.appearance().tintColor = UIColor(AppTheme.Colors.accent)

        let pillFill = UIColor(AppTheme.Colors.accent).withAlphaComponent(0.15)
        let pillStroke = UIColor(AppTheme.Colors.accent)
        let pill = MainTabView.makeSelectionIndicatorImage(fill: pillFill, stroke: pillStroke, cornerRadius: 12, lineWidth: 1)
        UITabBar.appearance().selectionIndicatorImage = pill
    }

    private static func makeSelectionIndicatorImage(fill: UIColor, stroke: UIColor, cornerRadius: CGFloat, lineWidth: CGFloat) -> UIImage {
        let size = CGSize(width: 60, height: 34) // base size; becomes resizable via cap insets
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: lineWidth/2, y: lineWidth/2, width: size.width - lineWidth, height: size.height - lineWidth)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            fill.setFill(); path.fill()
            stroke.setStroke(); path.lineWidth = lineWidth; path.stroke()
        }.resizableImage(withCapInsets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
    }

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

            HistoryView()
                .tabItem {
                    Label("Verlauf", systemImage: "clock.arrow.circlepath")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Einstellungen")
                }
        }
        .tint(AppTheme.Colors.accent)
        .background(AppTheme.Colors.background)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self, FavoriteMentorEntity.self, FavoritePlaylistEntity.self, WatchHistoryEntity.self)
        MainTabView()
            .modelContainer(container)
    }
}
