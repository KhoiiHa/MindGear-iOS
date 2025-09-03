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
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            ThumbnailView(
                urlString: video.thumbnailURL,
                width: 120,
                height: 70,
                cornerRadius: AppTheme.Radius.m
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(video.title)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail) // Lange Titel sauber abschneiden

                Text(video.description)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
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
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(isFavorite ? AppTheme.Colors.accent : AppTheme.Colors.iconSecondary)
                    .frame(width: 44, height: 44, alignment: .center)
            }
            .accessibilityIdentifier("favoriteButton")
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(isFavorite ? "Video aus Favoriten entfernen" : "Video zu Favoriten hinzufügen")
            .accessibilityHint("Favoritenstatus ändern.")
            .accessibilityAddTraits(.isButton)
        }
        .contentShape(Rectangle()) // komplette Zeile tappbar
        .padding(.vertical, AppTheme.Spacing.s)
        // Barrierefreiheit: Titel als Hauptlabel, Rest wird kombiniert
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("videoCell_\(video.id)")
        .accessibilityLabel(video.title)
        .accessibilityValue(isFavorite ? "In Favoriten" : "Nicht in Favoriten")
        .accessibilityHint("Doppeltippen, um Details zu öffnen.")
        .onAppear {
            isFavorite = FavoritesManager.shared.isVideoFavorite(video: video, context: context)
        }
    }
}
