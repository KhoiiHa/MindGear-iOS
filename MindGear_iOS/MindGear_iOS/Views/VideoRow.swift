//
//  VideoRow.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 01.08.25.
//



import SwiftUI

struct VideoRow: View {
    let video: Video

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail mit Ladezustand und Fallback bei Fehlern
            if let url = URL(string: video.thumbnailURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                            ProgressView()
                        }
                        .frame(width: 120, height: 70)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 70)
                            .clipped()
                            .cornerRadius(8)
                            .accessibilityHidden(true) // Bild ist dekorativ, Inhalt folgt im Text
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                            Image(systemName: "video.slash")
                        }
                        .frame(width: 120, height: 70)
                        .accessibilityHidden(true)
                    @unknown default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 120, height: 70)
                            .accessibilityHidden(true)
                    }
                }
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
        }
        .contentShape(Rectangle()) // komplette Zeile tappbar
        .padding(.vertical, 8)
        // Barrierefreiheit: Titel als Hauptlabel, Rest wird kombiniert
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(video.title))
        .accessibilityHint(Text("Doppeltippen, um Details zu öffnen."))
    }
}
