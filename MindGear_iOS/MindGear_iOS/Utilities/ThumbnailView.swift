//
//  ThumbnailView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

import SwiftUI

/// Robuste Thumbnail-Komponente mit Placeholder und statischem Fehlerbild.
/// Verwendung:
///   ThumbnailView(urlString: video.thumbnailURL, width: 160, height: 96, cornerRadius: 12)
struct ThumbnailView: View {
    // Eingaben
    let urlString: String
    var width: CGFloat = 160
    var height: CGFloat = 96
    var cornerRadius: CGFloat = 12

    var body: some View {
        let secure = urlString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "http://", with: "https://")

        return Group {
            if secure.isEmpty || URL(string: secure) == nil {
                failureView
            } else {
                AsyncImage(url: URL(string: secure)) { phase in
                    switch phase {
                    case .empty:
                        placeholder.redacted(reason: .placeholder)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    case .failure:
                        failureView
                    @unknown default:
                        placeholder
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Vorschaubild"))
    }

    // MARK: - Subviews

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
            Image(systemName: "video")
                .font(.title2)
                .foregroundStyle(.secondary)
                .opacity(0.35)
        }
    }

    private var failureView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
            Image(systemName: "video.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("ThumbnailView") {
    VStack(spacing: 16) {
        ThumbnailView(urlString: "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
        ThumbnailView(urlString: "https://invalid.invalid/image.jpg")
    }
    .padding()
    .background(Color(.systemBackground))
}
