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
        _viewModel = StateObject(wrappedValue: MentorViewModel(mentor: mentor))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Profilbild anzeigen
                if let url = URL(string: viewModel.mentor.profileImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .shadow(radius: 8)
                }

                // Name des Mentors anzeigen
                Text(viewModel.mentor.name)
                    .font(.title)
                    .fontWeight(.bold)

                // Biografie des Mentors anzeigen
                Text(viewModel.mentor.bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                // Soziale Links anzeigen, falls vorhanden
                if let socials = viewModel.mentor.socials, !socials.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(socials) { social in
                            Link(destination: URL(string: social.url)!) {
                                Text(social.platform)
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                } else {
                    // Hinweis, wenn keine Social-Links verfügbar sind
                    Text("Keine Social-Links verfügbar.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                // Playlists anzeigen und Navigation ermöglichen, falls vorhanden
                if let playlists = viewModel.mentor.playlists, !playlists.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playlists")
                            .font(.headline)
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: VideoListView(playlistID: playlist.playlistID, context: modelContext)) {
                                Text(playlist.title)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.top)
                } else {
                    // Hinweis, wenn keine Playlists verknüpft sind
                    Text("Keine Playlists verknüpft.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                // Link zum YouTube-Kanal des Mentors
                if let url = URL(string: "https://youtube.com/channel/\(viewModel.mentor.channelId)") {
                    Link("YouTube-Kanal ansehen", destination: url)
                        .padding(.top, 16)
                        .font(.headline)
                }
            }
            .padding()
        }
        .navigationTitle("Mentor-Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Herz-Button zum Favorisieren mit roter Farbe bei Favorit
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { @MainActor in
                        await viewModel.toggleFavorite(context: modelContext)
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isFavorite ? .red : .primary)
                }
                .animation(.easeInOut, value: viewModel.isFavorite)
            }
        }
        // Synchronisieren des Favoritenstatus beim Anzeigen der Ansicht
        .onAppear {
            Task { @MainActor in
                viewModel.syncFavorite(context: modelContext)
            }
        }
    }
}
