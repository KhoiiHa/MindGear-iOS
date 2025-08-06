//
//  MentorDetailView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI

struct MentorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var viewModel: MentorViewModel

    init(mentor: Mentor) {
        _viewModel = StateObject(wrappedValue: MentorViewModel(mentor: mentor))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Profilbild
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

                // Name
                Text(viewModel.mentor.name)
                    .font(.title)
                    .fontWeight(.bold)

                // Bio
                Text(viewModel.mentor.bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                // Social Links (optional)
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
                    Text("Keine Social-Links verfügbar.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                // Playlists (optional, als NavigationLink)
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
                    Text("Keine Playlists verknüpft.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                // Kanal-Link
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
    }
}

