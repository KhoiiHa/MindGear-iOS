//
//  ThumbnailView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 12.08.25.
//

import SwiftUI

/// Robuste Thumbnail-Komponente mit Placeholder, Fehlerzustand + Retry (Cache-Buster).
/// Verwendung:
///   ThumbnailView(urlString: video.thumbnailURL, width: 160, height: 96, cornerRadius: 12)
struct ThumbnailView: View {
    // Eingaben
    let urlString: String
    var width: CGFloat = 160
    var height: CGFloat = 96
    var cornerRadius: CGFloat = 12

    // State
    @State private var reloadToken = UUID()
    @State private var autoRetryDone = false

    var body: some View {
        AsyncImage(url: makeURL(urlString, token: reloadToken)) { phase in
            switch phase {
            case .empty:
                placeholder.redacted(reason: .placeholder)

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()

            case .failure:
                // 🔁 Einmaliger Auto-Retry mit frischem Cache-Buster
                if !autoRetryDone {
                    Color.clear
                        .onAppear {
                            #if DEBUG
                            print("🖼️ Thumb fail → Auto-Retry:", makeURL(urlString, token: reloadToken)?.absoluteString ?? "<nil>")
                            #endif
                            autoRetryDone = true
                            reloadToken = UUID()
                        }
                } else {
                    failureView
                }

            @unknown default:
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Vorschaubild"))
        .onChange(of: urlString) { _, _ in
            autoRetryDone = false
        }
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
            VStack(spacing: 6) {
                Image(systemName: "video.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Button("Neu laden") {
                    autoRetryDone = false
                    reloadToken = UUID() // zwingt AsyncImage zum Neu-Laden
                }
                .font(.caption2)
                .buttonStyle(.bordered)
            }
            .padding(6)
        }
    }

    // MARK: - Helper

    /// Cache-Buster via Query-Param, damit AsyncImage nach Fehlern wirklich neu lädt.
    private func makeURL(_ s: String, token: UUID) -> URL? {
        guard var comp = URLComponents(string: s) else { return URL(string: s) }
        // Entfernt bestehenden Cache-Buster, damit nicht mehrere ?t=... angehängt werden
        var items = (comp.queryItems ?? []).filter { $0.name != "t" }
        items.append(URLQueryItem(name: "t", value: token.uuidString))
        comp.queryItems = items
        return comp.url ?? URL(string: s)
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
