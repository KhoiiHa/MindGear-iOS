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
    @State private var reloadToken = UUID()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail mit Ladezustand, Fehler-Handler und manuellem Retry (Cache-Buster)
            AsyncImage(url: makeURL(video.thumbnailURL, token: reloadToken)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                        ProgressView()
                    }
                    .frame(width: 120, height: 70)
                    .accessibilityHidden(true)
                    .transition(.opacity)

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 70)
                        .clipped()
                        .cornerRadius(8)
                        .accessibilityHidden(true)
                        .transition(.opacity)

                case .failure:
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                            Image(systemName: "video.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.secondary)
                        }
                        Button("Neu laden") {
                            reloadToken = UUID() // triggert neuen AsyncImage-Request
                        }
                        .font(.caption2)
                    }
                    .frame(width: 120, height: 70)
                    .accessibilityHidden(true)
                    .transition(.opacity)

                @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 120, height: 70)
                        .accessibilityHidden(true)
                        .transition(.opacity)
                }
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
    // Baut eine URL mit Cache-Buster, damit AsyncImage bei gleichem Pfad nach einem Fehler neu lädt
    private func makeURL(_ s: String, token: UUID) -> URL? {
        guard var comp = URLComponents(string: s) else { return URL(string: s) }
        var items = comp.queryItems ?? []
        items.append(URLQueryItem(name: "t", value: token.uuidString))
        comp.queryItems = items
        return comp.url ?? URL(string: s)
    }
}
