//
//  MainTabView.swift
//  MindGear_iOS
//
//  Zweck: Tab-Leiste der App mit den Hauptbereichen (Home, Mentoren, Videos, Favoriten, Einstellungen).
//  Architekturrolle: SwiftUI View (präsentationsnah) mit UIKit-Brücke für TabBar-Aussehen.
//  Verantwortung: Tab-Struktur, Styling der UITabBar, Default-Selektion (für UI-Tests), Navigation-Container je Tab.
//  Warum? Klare Informationsarchitektur; UI-Tests finden stabile Einstiegspunkte über Accessibility-IDs.
//  Testbarkeit: Accessibility-IDs pro Tab, Preview mit In‑Memory ModelContainer.
//  Status: stabil.
//
import SwiftUI
import SwiftData
import UIKit

// Kurzzusammenfassung: Einheitliche TabBar (Blur, Farben), stabile Accessibility-IDs, UI-Test-sichere Default-Selektion.

// Tab-Bar der App mit Hauptbereichen
struct MainTabView: View {
    // MARK: - Types
    enum Tab: Hashable { case home, mentors, videos, favorites, settings }
    @State private var selection: Tab
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    init() {
        // TabBar-Styling zentral setzen (Blur, Farben, Titel) – wirkt auf alle Tabs
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()                    // system blur underlay
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
        appearance.backgroundColor = .clear
        appearance.shadowColor = UIColor(AppTheme.Colors.separator)

        // Einheitliche Icon/Title-Farben für normal/selected (auch inline/compactInline)
        let normalTitle   = [NSAttributedString.Key.foregroundColor: UIColor(AppTheme.textSecondary(for: .dark))]
        let selectedTitle = [NSAttributedString.Key.foregroundColor: UIColor(AppTheme.Colors.accent)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.textSecondary(for: .dark))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalTitle
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.Colors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedTitle
        appearance.inlineLayoutAppearance = appearance.stackedLayoutAppearance
        appearance.compactInlineLayoutAppearance = appearance.stackedLayoutAppearance

        // Auf globale UITabBar anwenden (Standard/ScrollEdge), inkl. Tints
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppTheme.textSecondary(for: .dark))
        UITabBar.appearance().tintColor = UIColor(AppTheme.Colors.accent)
        UITabBar.appearance().isTranslucent = true                     // enable blur behavior

        // Remove custom pill for now; we'll re-introduce later if desired
        UITabBar.appearance().selectionIndicatorImage = nil

        // UI-Tests: Optionaler Start auf "Mentoren" via Launch-Argument
        let wantsMentorsDefault = ProcessInfo.processInfo.arguments.contains("UITEST_DEFAULT_TAB_MENTORS")
        _selection = State(initialValue: wantsMentorsDefault ? .mentors : .home)
    }

    // MARK: - Helpers
    // Warum: Optionale Pill-Markierung (aktuell deaktiviert) – kann später reaktiviert werden
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

    // MARK: - Body
    var body: some View {
        TabView(selection: $selection) {
            // 1) Home – sichtbar
            NavigationStack { HomeView() }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("tab.home")
                }
                .accessibilityIdentifier("tab_home")
                .tag(Tab.home)

            // 2) Mentoren – sichtbar (XCUITest-relevant)
            NavigationStack { MentorsView() }
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("tab.mentors")
                }
                .accessibilityIdentifier("tab_mentors")
                .tag(Tab.mentors)

            // 3) Videos – sichtbar
            NavigationStack { VideoListView(playlistID: ConfigManager.recommendedPlaylistId, context: context) }
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("tab.videos")
                }
                .accessibilityIdentifier("tab_videos")
                .tag(Tab.videos)

            // 4) Favoriten – sichtbar
            NavigationStack { FavoritenView(context: context) }
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("tab.favorites")
                }
                .accessibilityIdentifier("tab_favorites")
                .tag(Tab.favorites)

            // 5) Einstellungen – sichtbar (XCUITest-relevant)
            NavigationStack { SettingsView() }
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("settings.title")
                }
                .accessibilityIdentifier("tab_settings")
                .tag(Tab.settings)

            // 6+) Weitere Tabs – landen automatisch unter "Mehr"
            NavigationStack { CategoriesView() }
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("categories.title")
                }

            NavigationStack { PlaylistView(playlistId: ConfigManager.recommendedPlaylistId, context: context) }
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("playlists.title")
                }

            NavigationStack { HistoryView() }
                .tabItem {
                    Label("history.title", systemImage: "clock.arrow.circlepath")
                }
        }
        .tint(AppTheme.Colors.accent)
        .toolbar(.visible, for: .tabBar)
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self, FavoriteMentorEntity.self, FavoritePlaylistEntity.self, WatchHistoryEntity.self)
        MainTabView()
            .modelContainer(container)
        MainTabView()
            .modelContainer(container)
            .preferredColorScheme(.dark)
    }
}
