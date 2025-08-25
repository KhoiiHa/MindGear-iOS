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
        appearance.configureWithDefaultBackground()                    // system blur underlay
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
        appearance.backgroundColor = .clear
        appearance.shadowColor = UIColor(AppTheme.Colors.separator)

        let normalTitle   = [NSAttributedString.Key.foregroundColor: UIColor(AppTheme.Colors.textSecondary)]
        let selectedTitle = [NSAttributedString.Key.foregroundColor: UIColor(AppTheme.Colors.accent)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.Colors.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalTitle
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.Colors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedTitle
        appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
        appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppTheme.Colors.textSecondary)
        UITabBar.appearance().tintColor = UIColor(AppTheme.Colors.accent)
        UITabBar.appearance().isTranslucent = true                     // enable blur behavior

        // Remove custom pill for now; we'll re-introduce later if desired
        UITabBar.appearance().selectionIndicatorImage = nil
    }

    private static func makeSelectionIndicatorImage(fill: UIColor, stroke: UIColor, cornerRadius: CGFloat, lineWidth: CGFloat) -> UIImage {
        let size = CGSize(width: 56, height: 28) // slimmer pill; resizable via cap insets
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(x: lineWidth/2, y: lineWidth/2, width: size.width - lineWidth, height: size.height - lineWidth)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            fill.setFill(); path.fill()
            stroke.setStroke(); path.lineWidth = lineWidth; path.stroke()
        }.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            NavigationStack { VideoListView(playlistID: ConfigManager.recommendedPlaylistId, context: context) }
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("Videos")
                }

            NavigationStack { FavoritenView(context: context) }
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favoriten")
                }

            NavigationStack { CategoriesView() }
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Kategorien")
                }

            NavigationStack { MentorsView(mentors: allMentors) }
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Mentoren")
                }

            NavigationStack { PlaylistView(playlistId: ConfigManager.recommendedPlaylistId, context: context) }
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Playlists")
                }

            NavigationStack { HistoryView() }
                .tabItem {
                    Label("Verlauf", systemImage: "clock.arrow.circlepath")
                }

            NavigationStack { SettingsView() }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Einstellungen")
                }
        }
        .tint(AppTheme.Colors.accent)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self, FavoriteMentorEntity.self, FavoritePlaylistEntity.self, WatchHistoryEntity.self)
        MainTabView()
            .modelContainer(container)
    }
}
