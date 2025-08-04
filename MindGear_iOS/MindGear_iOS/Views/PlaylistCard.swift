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

    var body: some View {
        NavigationLink {
            VideoListView(playlistID: playlistID, context: context)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}
