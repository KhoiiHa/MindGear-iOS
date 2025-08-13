import SwiftUI

/// Schlanker Thumbnail-Loader (ohne Cache/Helper)
/// - Erzwingt HTTPS
/// - Nutzt bis zu zwei Host-Kandidaten (i.ytimg.com → img.youtube.com)
/// - Genau ein automatischer Fallback-Retry (0,3 s)
/// - Optional: Tap-to-Retry
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

    /// Bis zu zwei Kandidaten: Original & alternativer Host (img.youtube.com), falls i.ytimg.com
    private var candidateURLs: [URL] {
        let primary = sanitize(urlString)
        var list: [String] = []
        if !primary.isEmpty, let u = URL(string: primary) { list.append(u.absoluteString) }
        if primary.contains("i.ytimg.com") {
            let alt = primary.replacingOccurrences(of: "i.ytimg.com", with: "img.youtube.com")
            if let u = URL(string: alt) { list.append(u.absoluteString) }
        }
        let unique = Array(Set(list))
        return unique.compactMap { URL(string: $0) }
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Vorschaubild"))
            // Bei neuem Inhalt: Retry-Zustand zurücksetzen
            .task(id: urlString) { attempt = 0 }
    }

    @ViewBuilder
    private var content: some View {
        if let url = currentURL {
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
                        // Genau ein Auto-Fallback auf alternativen Host
                        if attempt == 0 && candidateURLs.count > 1 {
                            Color.clear
                                .task {
                                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 s
                                    attempt = 1
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
            }
        } else {
            // Kein gültiger URL-Kandidat
            failureView
                .modifier(TapToRetry(enabled: enableTapToRetry) {
                    attempt = 0
                })
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
            Image(systemName: "video.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Aktiviert einen Tap-to-Retry nur bei Bedarf (kein Extra-API in der aufrufenden View nötig).
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
