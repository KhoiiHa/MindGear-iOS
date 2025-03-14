//
//  FavoritenView.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var viewModel = FavoritesViewModel()  // ViewModel wird hier eingebunden
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.favoriteChannels) { channel in
                    Section(header: Text(channel.name)) {
                        ForEach(channel.videos) { video in
                            HStack {
                                // Thumbnail oder ein Bild anzeigen
                                Image(systemName: "play.circle.fill") // Platzhalter für das Thumbnail
                                    .frame(width: 40, height: 40)
                                    .padding()

                                VStack(alignment: .leading) {
                                    Text(video.title)
                                        .font(.headline)

                                    if let description = video.description {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }

                                Spacer()

                                Button(action: {
                                    viewModel.removeFavorite(channel: channel, video: video)  // Favoriten entfernen
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("Favoriten")
            .onAppear {
                viewModel.loadFavorites()  // Favoriten laden
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
