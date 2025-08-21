//
//  PlaylistCard.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.08.25.
//

import SwiftUI
import SwiftData

struct PlaylistCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let playlistID: String
    let context: ModelContext

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationLink {
            VideoListView(playlistID: playlistID, context: context)
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(AppTheme.Colors.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    Text(subtitle)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                AppTheme.Icons.chevronRight
                    .font(.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.vertical, AppTheme.Spacing.m)
            .padding(.horizontal, AppTheme.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                    .stroke(AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: AppTheme.Colors.shadowCard, radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .contentShape(Rectangle())
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(subtitle)")
            .accessibilityHint("Öffnet Playlist.")
        }
    }
}
