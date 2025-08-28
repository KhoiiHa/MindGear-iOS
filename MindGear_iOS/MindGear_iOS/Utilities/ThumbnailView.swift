import SwiftUI
import UIKit

final class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private let cache = NSCache<NSURL, UIImage>()
    private init() { cache.countLimit = 200 }
    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

/// MindGear ThumbnailView – robust & bewusst „lean“ gebaut
///
/// Warum diese View existiert (sichtbar für Reviewer/Bewerter):
/// - YouTube-Thumbnails sind inkonsistent (Host/Resolution/CDN). Häufige Fälle: 404 bei
///   `maxresdefault.jpg` oder Host-Hänger.
/// - Ziel: **zuverlässige Anzeige** bei minimaler Komplexität – kein Over-Engineering.
///
/// Design-Entscheidungen (Safety-first, aber schlank):
/// - HTTPS erzwingen (keine ATS-Reibung)
/// - Kandidaten-Reihenfolge: **Original → hqdefault → Alt‑Host (img.youtube.com) → Alt‑Host+hqdefault**
///   ↳ `hqdefault.jpg` ist fast immer vorhanden und stabiler als `maxresdefault`/`sddefault`.
/// - Genau **ein** Auto‑Retry (0,3 s) – keine Schleifen, ruhige UI
/// - Cache‑First: Wenn `URLCache` einen Treffer hat, sofort rendern (snappier UX)
/// - Kein Fade‑In bei `AsyncImage` (fühlt sich schneller an)
/// - Optional: Tap‑to‑Retry, ohne zusätzliche Infrastruktur
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
    private func sanitize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .replacingOccurrences(of: "http://", with: "https://")
    }

    /// Kandidaten-Reihenfolge (in genau dieser Reihenfolge, ohne Set!):
    /// 1) Original
    /// 2) Kleinere Auflösung (hqdefault) – häufigster Fix
    /// 3) Alt-Host (img.youtube.com)
    /// 4) Alt-Host + Kleinere Auflösung
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
            // 0) Memory cache first
            if let mem = ImageMemoryCache.shared.image(for: url) {
                Image(uiImage: mem)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
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
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    await MainActor.run {
                                        if attempt < max(0, candidateURLs.count - 1) {
                                            attempt = min(attempt + 1, candidateURLs.count - 1)
                                        }
                                    }
                                }
                            } catch {
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
        }
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
}

/// Aktiviert einen Tap‑to‑Retry nur bei Bedarf (kein Extra‑API in der aufrufenden View nötig).
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
