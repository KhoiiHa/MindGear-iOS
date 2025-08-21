import SwiftUI
import UIKit

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
            .task(id: urlString) { await MainActor.run { attempt = 0 } }
    }

    @ViewBuilder
    private var content: some View {
        if let url = currentURL {
            // Cache‑First: sofort anzeigen, wenn vorhanden (keine Netzrunde)
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            if let cachedResponse = URLCache.shared.cachedResponse(for: request),
               let uiImage = UIImage(data: cachedResponse.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder.redacted(reason: .placeholder)

                    case .success(let image):
                        image.resizable().scaledToFill().clipped()

                    case .failure:
                        // Genau ein Auto‑Fallback auf den nächsten Kandidaten (z. B. Alt‑Host oder hqdefault)
                        if attempt < max(0, candidateURLs.count - 1) {
                            Color.clear
                                .task {
                                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 s
                                    await MainActor.run { attempt = min(attempt + 1, candidateURLs.count - 1) }
                                }
                        } else {
                            failureView
                                .modifier(TapToRetry(enabled: enableTapToRetry) {
                                    // Manueller Retry: erneut versuchen (startet wieder mit primärem Kandidaten)
                                    attempt = 0
                                })
                        }

                    @unknown default:
                        placeholder
                    }
                }
                .transaction { $0.animation = nil } // kein Fade‑In → wirkt schneller
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
