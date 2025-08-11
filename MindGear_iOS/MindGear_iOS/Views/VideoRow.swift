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
            // Thumbnail mit Ladezustand und Fallback bei Fehlern
            if let url = URL(string: video.thumbnailURL) {
                AsyncImage(url: url)
                    .id(video.thumbnailURL)
                    .transition(.opacity)
                    .frame(width: 120, height: 70)
                    .cornerRadius(8)
                    .overlay(
                        Group {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.15))
                                        ProgressView()
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 70)
                                        .clipped()
                                        .accessibilityHidden(true) // Bild ist dekorativ, Inhalt folgt im Text
                                case .failure:
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.15))
                                        Image(systemName: "video.slash")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.secondary)
                                    }
                                    .accessibilityHidden(true)
                                @unknown default:
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.15))
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 70)
                    .accessibilityHidden(true)
            }

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
        }
        .contentShape(Rectangle()) // komplette Zeile tappbar
        .padding(.vertical, 8)
        // Barrierefreiheit: Titel als Hauptlabel, Rest wird kombiniert
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(video.title))
        .accessibilityHint(Text("Doppeltippen, um Details zu öffnen."))
        .onAppear {
            isFavorite = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
        }
    }
}
