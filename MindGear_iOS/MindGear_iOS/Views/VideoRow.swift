//
//  VideoRow.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 01.08.25.
//



import SwiftUI

struct VideoRow: View {
    let video: Video
    @Environment(\.modelContext) private var context
    @State private var isFavorite: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ThumbnailView(
                urlString: video.thumbnailURL,
                width: 120,
                height: 70,
                cornerRadius: 8
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                    .truncationMode(.tail) // Lange Titel sauber abschneiden

                Text(video.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail) // Lange Beschreibungen sauber abschneiden
                    .accessibilityLabel(Text(video.description))
            }

            Spacer(minLength: 8)

            Button {
                Task { @MainActor in
                    await FavoritesManager.shared.toggleVideoFavorite(video: video, context: context)
                    isFavorite = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
                }
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isFavorite ? .red : .secondary)
                    .padding(.top, 2)
            }
            .accessibilityLabel(isFavorite ? "Video aus Favoriten entfernen" : "Video zu Favoriten hinzufügen")
            .accessibilityHint("Favoritenstatus ändern.")
            .accessibilityAddTraits(.isButton)
        }
        .contentShape(Rectangle()) // komplette Zeile tappbar
        .padding(.vertical, 8)
        // Barrierefreiheit: Titel als Hauptlabel, Rest wird kombiniert
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(video.title))
        .accessibilityValue(isFavorite ? "In Favoriten" : "Nicht in Favoriten")
        .accessibilityHint(Text("Doppeltippen, um Details zu öffnen."))
        .onAppear {
            isFavorite = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
        }
    }
}
