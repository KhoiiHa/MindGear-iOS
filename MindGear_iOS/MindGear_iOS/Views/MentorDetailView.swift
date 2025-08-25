//
//  MentorDetailView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI
import SwiftData

@MainActor
struct MentorDetailView: View {
    private var modelContext: ModelContext
    @StateObject var viewModel: MentorViewModel

    init(mentor: Mentor, context: ModelContext) {
        self.modelContext = context
        _viewModel = StateObject(wrappedValue: MentorViewModel(mentor: mentor, context: context))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: AppTheme.Spacing.l) {
                // Profilbild anzeigen
                if let urlStr = viewModel.mentor.profileImageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundStyle(AppTheme.Colors.iconSecondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.Colors.accent, lineWidth: 2))
                    .shadow(color: AppTheme.Colors.shadowCard.opacity(0.6), radius: 12, x: 0, y: 6)
                }

                // Name des Mentors anzeigen
                Text(viewModel.mentor.name)
                    .font(AppTheme.Typography.title)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                // Biografie des Mentors anzeigen
                if let bio = viewModel.mentor.bio {
                    Text(bio)
                        .font(AppTheme.Typography.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                // Soziale Links anzeigen, falls vorhanden
                if let socials = viewModel.mentor.socials, !socials.isEmpty {
                    HStack(spacing: AppTheme.Spacing.m) {
                        ForEach(socials) { social in
                            Link(destination: URL(string: social.url)!) {
                                Text(social.platform)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }
                        }
                    }
                } else {
                    // Hinweis, wenn keine Social-Links verfügbar sind
                    Text("Keine Social-Links verfügbar.")
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }

                // Playlists anzeigen und Navigation ermöglichen, falls vorhanden
                if let playlists = viewModel.mentor.playlists, !playlists.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text("Playlists")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: VideoListView(playlistID: playlist.playlistID, context: modelContext)) {
                                Text(playlist.title)
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal, AppTheme.Spacing.m)
                } else {
                    // Hinweis, wenn keine Playlists verknüpft sind
                    Text("Keine Playlists verknüpft.")
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }

                // Link zum YouTube-Kanal des Mentors
                if let url = URL(string: "https://youtube.com/channel/\(viewModel.mentor.id)") {
                    Link("YouTube-Kanal ansehen", destination: url)
                        .padding(.top, 16)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .padding(AppTheme.Spacing.l)
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Mentor-Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Herz-Button zum Favorisieren mit roter Farbe bei Favorit
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { @MainActor in
                        await viewModel.toggleFavorite()
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite ? AppTheme.Colors.danger : AppTheme.Colors.iconPrimary)
                }
                .animation(.easeInOut, value: viewModel.isFavorite)
            }
        }
        // Synchronisieren des Favoritenstatus beim Anzeigen der Ansicht
        .onAppear { viewModel.startObservingFavorites() }
    }
}
