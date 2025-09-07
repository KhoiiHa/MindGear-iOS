//
//  ThumbnailView.swift
//  MindGear_iOS
//
//  Zweck: Zuverlässige Anzeige von YouTube‑Thumbnails mit einfachen Fallbacks & Cache‑Nutzung.
//  Architekturrolle: SwiftUI View (präsentationsnah) + leichter Cache‑Utility.
//  Verantwortung: URL‑Normalisierung, Kandidaten‑Reihenfolge, schlanker Auto‑Retry, Memory/URLCache‑Nutzung.
//  Warum? i.ytimg.com liefert nicht immer `maxresdefault`/`sddefault`; stabile Anzeige ohne Over‑Engineering.
//  Testbarkeit: Deterministischer Ablauf; Preview möglich; keine externen Abhängigkeiten.
//  Status: stabil.
//

import SwiftUI
import UIKit
// Kurzzusammenfassung: Kandidaten: Original → hqdefault → Alt‑Host → Alt‑Host+hq; 1 Retry (300ms); Memory+URLCache first.

// MARK: - ImageMemoryCache (leichtgewichtig)
/// Kleiner In‑Memory‑Cache für bereits geladene Thumbnails (reduziert Netz/Decoding‑Kosten).
final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSURL, UIImage>()
    private init() { cache.countLimit = 200 }
    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

// MARK: - ThumbnailView
// Warum: Robuste Anzeige trotz inkonsistenter YouTube‑CDN‑Antworten; bewusst schlank gehalten.
struct ThumbnailView: View {
    let urlString: String
    var width: CGFloat = 160
    var height: CGFloat = 96
    var cornerRadius: CGFloat = 12
    var enableTapToRetry: Bool = false

    /// 0 = primäre URL, 1 = alternative Host-URL (nur falls ytimg)
    @State private var attempt = 0
    @State private var uiImage: UIImage? = nil

    // MARK: - Helpers
    /// Erzwingt HTTPS & trimmt Whitespace.
    /// Warum: Vermeidet ATS‑Probleme & instabile Vergleiche.
    private func sanitize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .replacingOccurrences(of: "http://", with: "https://")
    }

    /// Erzeugt die Kandidaten‑Liste in fixer Reihenfolge.
    /// Warum: `hqdefault` ist fast immer verfügbar; Alt‑Host hilft bei CDN‑Ausfällen.
    private var candidateURLs: [URL] {
        let primary = sanitize(urlString)

        func swapHost(_ s: String) -> String { s.replacingOccurrences(of: "i.ytimg.com", with: "img.youtube.com") }
        func lowerRes(_ s: String) -> String {
            s.replacingOccurrences(of: "maxresdefault.jpg", with: "hqdefault.jpg")
             .replacingOccurrences(of: "sddefault.jpg",   with: "hqdefault.jpg")
        }

        var ordered: [String] = []
        func add(_ s: String) { if !s.isEmpty, !ordered.contains(s) { ordered.append(s) } }

        // 1) original
        add(primary)

        // 2) kleinere Auflösung aus gleicher URL
        if primary.contains("maxresdefault") || primary.contains("sddefault") {
            add(lowerRes(primary))
        }

        // 3) alt-host Varianten der bisherigen Kandidaten
        if primary.contains("i.ytimg.com") {
            add(swapHost(primary))
            if primary.contains("maxresdefault") || primary.contains("sddefault") {
                add(lowerRes(swapHost(primary)))
            }
        } else if primary.contains("hqdefault.jpg") {
            // Falls bereits hqdefault: sicherheitshalber auch Alt‑Host anfügen
            add(swapHost(primary))
        }

        // 4) Falls die URL ein /vi/<id>/ enthält, konstruiere stabile hqdefault‑Kandidaten explizit
        if let comps = URLComponents(string: primary) {
            let path = comps.path
            let parts = path.split(separator: "/", omittingEmptySubsequences: true)
            if let viIndex = parts.firstIndex(of: "vi"), viIndex + 1 < parts.count {
                let videoID = String(parts[viIndex + 1])
                add("https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
                add("https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
            }
        }

        return ordered.compactMap { URL(string: $0) }
    }

    /// Liefert die aktuelle Kandidaten‑URL basierend auf `attempt`.
    private var currentURL: URL? {
        guard !candidateURLs.isEmpty else { return nil }
        let idx = min(attempt, candidateURLs.count - 1)
        return candidateURLs[idx]
    }

    // MARK: - Body
    var body: some View {
        content
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .accessibilityLabel("Vorschaubild")
            .accessibilityElement(children: .ignore)
            // Bei neuem Inhalt: Retry-Zustand zurücksetzen
            .task(id: urlString) { await MainActor.run {
                attempt = 0
                uiImage = nil
            } }
    }

    @ViewBuilder
    private var content: some View {
        if let img = uiImage {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .clipped()
        } else if let url = currentURL {
            // Cache‑Policy: Zeige Cache sofort, lade im Hintergrund nach (snappier UX)
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            // 0) Memory cache first
            if let mem = ImageMemoryCache.shared.image(for: url) {
                Image(uiImage: mem)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                if let cachedResponse = URLCache.shared.cachedResponse(for: request),
                   let cachedImage = UIImage(data: cachedResponse.data) {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .task { ImageMemoryCache.shared.insert(cachedImage, for: url) }
                } else {
                    placeholder
                        .redacted(reason: .placeholder)
                        .task {
                            do {
                                let (data, _) = try await URLSession.shared.data(for: request)
                                if let loaded = UIImage(data: data) {
                                    ImageMemoryCache.shared.insert(loaded, for: url)
                                    await MainActor.run { self.uiImage = loaded }
                                } else {
                                    // Ruhiger Auto‑Retry nach 300ms (ein Schritt weiter in der Kandidatenliste)
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    await MainActor.run {
                                        if attempt < max(0, candidateURLs.count - 1) {
                                            attempt = min(attempt + 1, candidateURLs.count - 1)
                                        }
                                    }
                                }
                            } catch {
                                // Ruhiger Auto‑Retry nach 300ms (ein Schritt weiter in der Kandidatenliste)
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                await MainActor.run {
                                    if attempt < max(0, candidateURLs.count - 1) {
                                        attempt = min(attempt + 1, candidateURLs.count - 1)
                                    }
                                }
                            }
                        }
                }
            }
        } else {
            // Kein gültiger URL‑Kandidat → klarer Fallback
            failureView
                .modifier(TapToRetry(enabled: enableTapToRetry) { attempt = 0 })
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
                .opacity(0.55)
                .accessibilityHidden(true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private var failureView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.secondary.opacity(0.12))
            Image(systemName: "video.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
                .opacity(0.75)
                .accessibilityHidden(true)
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Modifiers
/// Aktiviert Tap‑to‑Retry nur, wenn gewünscht – ohne zusätzliche Zustände in aufrufenden Views.
private struct TapToRetry: ViewModifier {
    let enabled: Bool
    let action: () -> Void
    func body(content: Content) -> some View {
        if enabled {
            content
                .contentShape(Rectangle())
                .onTapGesture { action() }
        } else {
            content
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        ThumbnailView(urlString: "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg", width: 240, height: 135)
        ThumbnailView(urlString: "https://i.ytimg.com/vi/invalid-id/maxresdefault.jpg", width: 240, height: 135, enableTapToRetry: true)
    }
    .padding()
}
