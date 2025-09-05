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
            ZStack(alignment: .top) {
                // Background (AppTheme-driven)
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                // Header tint: subtle and short, faded to transparent
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

                        Spacer(minLength: AppTheme.Spacing.s)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.l)
                    .scrollIndicators(.hidden)
                }
            }
        }
        
    }
}

#Preview {
    HomeView()
}
