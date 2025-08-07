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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Willkommensbereich
                    VStack(alignment: .leading, spacing: 8) {
                        Text("👋 Willkommen zurück!")
                            .font(.title)
                            .bold()
                        Text("Welche Perspektive bringt dich heute weiter?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    let playlists: [PlaylistInfo] = [
                        PlaylistInfo(title: "Die M.E.N. Series", subtitle: "ChrisWillx", iconName: "star.circle.fill", playlistID: ConfigManager.recommendedPlaylistId),
                        PlaylistInfo(title: "On Purpose", subtitle: "Jay Shetty", iconName: "leaf.fill", playlistID: ConfigManager.jayShettyPlaylistId),
                        PlaylistInfo(title: "The Diary Of A CEO", subtitle: "Steven Bartlett", iconName: "book.circle.fill", playlistID: ConfigManager.diaryOfACeoPlaylistId),
                        PlaylistInfo(title: "This Past Weekend", subtitle: "Theo Von", iconName: "mic.circle.fill", playlistID: ConfigManager.theoVonPlaylistId),
                        PlaylistInfo(title: "Psychology & Society", subtitle: "Jordan B. Peterson", iconName: "brain.head.profile", playlistID: ConfigManager.jordanBPetersonPlaylistId),
                        PlaylistInfo(title: "Leadership & Inspiration", subtitle: "Simon Sinek", iconName: "person.3.sequence.fill", playlistID: ConfigManager.simonSinekPlaylistId),
                        PlaylistInfo(title: "Shaolin Wisdom", subtitle: "Shi Heng Yi", iconName: "flame.fill", playlistID: ConfigManager.shiHengYiPlaylistId),
                                     PlaylistInfo(title: "The Shawn Ryan Show", subtitle: "Shawn Ryan", iconName: "shield.lefthalf.fill", playlistID: ConfigManager.shawnRyanPlaylistId),
                    ]

                    VStack(alignment: .leading, spacing: 12) {
                        Text("🧠 Deine Mentoren")
                            .font(.headline)

                        ForEach(playlists) { playlist in
                            NavigationLink(
                                destination: VideoListView(playlistID: playlist.playlistID, context: context)
                            ) {
                                PlaylistCard(
                                    title: playlist.title,
                                    subtitle: "Playlist von \(playlist.subtitle)",
                                    iconName: playlist.iconName,
                                    playlistID: playlist.playlistID,
                                    context: context
                                )
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("🏠 Startseite")
        }
    }
}

// MARK: - SwiftLint Test

func throwingFunction() throws -> String {
    return "Das ist ein Test für SwiftLint"
}

func testForceTry() {
    let _ = try! throwingFunction() // ⛔️ force_try
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self)
        HomeView()
            .modelContainer(container)
    }
}
