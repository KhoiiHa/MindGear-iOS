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
            let appErr = AppError.from(error)
            #if DEBUG
            print("ℹ️ [Home] Remote‑Playlists fehlgeschlagen → Fallback: \(appErr.localizedDescription)")
            #endif
            self.errorMessage = appErr.recoverySuggestion ?? appErr.errorDescription
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var rvm = HomeRemoteViewModel()
    @Environment(\.colorScheme) private var scheme
    @State private var searchText: String = ""

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
                            Text("home.title")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppTheme.textPrimary(for: scheme))
                                .accessibilityHeading(.h1)
                                .accessibilityIdentifier("homeHeaderTitle")
                            Text("home.subtitle")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary(for: scheme))
                                .padding(.bottom, AppTheme.Spacing.m)

                            // Inline‑Search unter dem Titel
                            SearchField(
                                text: $searchText,
                                placeholder: NSLocalizedString("search.placeholder", comment: ""),
                                suggestions: [],
                                accessibilityHintKey: "search.generic.hint",
                                onSubmit: {},
                                onTapSuggestion: { q in searchText = q },
                                accessibilityIdentifier: "homeSearch"
                            )
                            .padding(.top, AppTheme.Spacing.s)
                        }
                        .padding(.top, AppTheme.Spacing.m)
                        .padding(.bottom, AppTheme.Spacing.s)
                        .frame(minHeight: 0, alignment: .topLeading)

                        // Nicht-blockierendes Fehler-Feedback für Remote‑Teaser
                        if let msg = rvm.errorMessage, !msg.isEmpty {
                            ErrorBanner(message: msg) {
                                rvm.errorMessage = nil
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                        }

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
                            SectionHeader(title: "section.recommended")

                            if rvm.isLoading && rvm.remotePlaylists.isEmpty {
                                HStack {
                                    ProgressView()
                                    Text("loading.playlists")
                                        .font(.footnote)
                                        .foregroundStyle(AppTheme.textSecondary(for: scheme))
                                }
                                .padding(.vertical, AppTheme.Spacing.s)
                            }

                            // Remote bevorzugen, Seeds auffüllen, Duplikate entfernen
                            let displayed = (rvm.remotePlaylists + playlists).dedupByPlaylistID()
                            ForEach(displayed) { playlist in
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

// MARK: - Helpers
private extension Array where Element == PlaylistInfo {
    /// Entfernt Duplikate anhand der `playlistID` und behält die Reihenfolge (Remote vor Seeds)
    func dedupByPlaylistID() -> [PlaylistInfo] {
        var seen = Set<String>()
        var result: [PlaylistInfo] = []
        for p in self {
            if seen.insert(p.playlistID).inserted { result.append(p) }
        }
        return result
    }
}

#Preview {
    Group {
        HomeView()
        HomeView().preferredColorScheme(.dark)
    }
}
