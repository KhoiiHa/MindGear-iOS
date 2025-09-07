//
//  HomeView.swift
//  MindGear_iOS
//
//  Zweck: Startseite mit empfohlenen Playlists (Remote‑Cache) und kuratierten Mentoren.
//  Architekturrolle: SwiftUI View (präsentationsnah) + leichtes Remote‑ViewModel.
//  Verantwortung: Header, Sektionen, Remote‑Teaser, Navigation zu Playlists.
//  Warum? Schlanke UI; Datenbeschaffung & Caching liegen in Services (RemoteCacheService).
//  Testbarkeit: Previews + klare Accessibility‑IDs.
//  Status: stabil.
//

import SwiftUI
import SwiftData

// Kurzzusammenfassung: Oben Titel/Unterzeile, darunter Remote‑Playlists (GitHub Cache) oder lokale Kuratierung.

// MARK: - HomeRemoteViewModel (leichtgewichtig)
// Warum: Lädt einmalig einen Remote‑Teaser; UI bleibt responsiv ohne harte Abhängigkeit.
@MainActor
private final class HomeRemoteViewModel: ObservableObject {
    // MARK: - State
    @Published var remotePlaylists: [PlaylistInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Lädt einmalig Remote‑Playlists aus dem GitHub‑Cache.
    /// Warum: Schneller perceived Load ohne direkte API‑Kosten; UI fällt bei Fehlern auf lokale Kuratierung zurück.
    func load() async {
        guard remotePlaylists.isEmpty else { return } // only once per appearance
        isLoading = true; defer { isLoading = false }
        do {
            // Datenquelle: Remote‑Cache (GitHub Actions) – robust & günstig
            let remote = try await RemoteCacheService.loadPlaylists()
            // Mapping: Remote‑Schema → App‑Modell (PlaylistInfo)
            let mapped: [PlaylistInfo] = remote.playlists.map { m in
                let thumb = m.thumbnails?.high ?? m.thumbnails?.medium ?? m.thumbnails?.`default`
                return PlaylistInfo(
                    title: m.title,
                    subtitle: m.channelTitle ?? (m.mentor ?? "Playlist"),
                    iconName: "play.circle.fill",
                    playlistID: m.id,
                    thumbnailURL: thumb
                )
            }
            self.remotePlaylists = mapped
        } catch {
            // Fallback: Keine harten Fehler in der UI – lokale Kuratierung verwenden
            print("ℹ️ [Home] Remote‑Playlists fehlgeschlagen → Fallback: \(error.localizedDescription)")
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var rvm = HomeRemoteViewModel()

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background (AppTheme-driven)
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                // Warum: Oberer Verlauf gibt Tiefe/Lesbarkeit, ohne Inhalte zu überdecken
                AppTheme.headerGradient
                    .mask(
                        LinearGradient(
                            colors: [Color.white, Color.white, Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 120)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)

                // CONTENT
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {

                        // Modernized header
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                            // Seitenkopf: klare Hierarchie (H1 + Subheadline)
                            Text("Startseite")
                                .font(AppTheme.Typography.title)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .accessibilityHeading(.h1)
                                .accessibilityIdentifier("homeHeaderTitle")
                            Text("Welche Perspektive bringt dich heute weiter?")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .padding(.bottom, AppTheme.Spacing.s)
                        }
                        .padding(.top, AppTheme.Spacing.m)

                        let playlists: [PlaylistInfo] = [
                            PlaylistInfo(title: "Die M.E.N. Series", subtitle: "ChrisWillx", iconName: "star.circle.fill", playlistID: ConfigManager.recommendedPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "On Purpose", subtitle: "Jay Shetty", iconName: "leaf.fill", playlistID: ConfigManager.jayShettyPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "The Diary Of A CEO", subtitle: "Steven Bartlett", iconName: "book.circle.fill", playlistID: ConfigManager.diaryOfACeoPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "This Past Weekend", subtitle: "Theo Von", iconName: "mic.circle.fill", playlistID: ConfigManager.theoVonPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "Psychology & Society", subtitle: "Jordan B. Peterson", iconName: "brain.head.profile", playlistID: ConfigManager.jordanBPetersonPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "Leadership & Inspiration", subtitle: "Simon Sinek", iconName: "person.3.sequence.fill", playlistID: ConfigManager.simonSinekPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "Shaolin Wisdom", subtitle: "Shi Heng Yi", iconName: "flame.fill", playlistID: ConfigManager.shiHengYiPlaylistId, thumbnailURL: nil),
                            PlaylistInfo(title: "The Shawn Ryan Show", subtitle: "Shawn Ryan", iconName: "shield.lefthalf.fill", playlistID: ConfigManager.shawnRyanPlaylistId, thumbnailURL: nil),
                        ]

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                            Text("Empfohlen")
                                .font(AppTheme.Typography.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .textCase(.uppercase)

                            Text("Deine Mentoren")
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                                .textCase(.uppercase)
                                .tracking(0.6)
                                .accessibilityHeading(.h2)
                                .accessibilityLabel("Deine Mentoren")
                                .accessibilityIdentifier("homeMentorsSectionTitle")

                            if rvm.isLoading && rvm.remotePlaylists.isEmpty {
                                HStack {
                                    ProgressView()
                                    Text("Lade empfohlene Playlists…")
                                        .font(AppTheme.Typography.footnote)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                                .padding(.vertical, AppTheme.Spacing.s)
                            } else if !rvm.remotePlaylists.isEmpty {
                                // Karten: Navigations‑Teaser zu PlaylistView
                                ForEach(rvm.remotePlaylists) { playlist in
                                    PlaylistCard(
                                        title: playlist.title,
                                        subtitle: "Playlist von \(playlist.subtitle)",
                                        iconName: playlist.iconName,
                                        playlistID: playlist.playlistID,
                                        context: context
                                    )
                                    .mgCard()
                                    .accessibilityIdentifier("homePlaylistCard_\(playlist.playlistID)")
                                }
                            } else {
                                // Karten: Navigations‑Teaser zu PlaylistView
                                ForEach(playlists) { playlist in
                                    PlaylistCard(
                                        title: playlist.title,
                                        subtitle: "Playlist von \(playlist.subtitle)",
                                        iconName: playlist.iconName,
                                        playlistID: playlist.playlistID,
                                        context: context
                                    )
                                    .mgCard()
                                    .accessibilityIdentifier("homePlaylistCard_\(playlist.playlistID)")
                                }
                            }
                        }

                        Spacer(minLength: AppTheme.Spacing.s)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.l)
                    .scrollIndicators(.hidden)
                }
                .task { await rvm.load() }
                .refreshable { await rvm.load() }
            }
        }
        
    }
}

#Preview {
    HomeView()
    HomeView().preferredColorScheme(.dark)
}
