import SwiftUI
import WebKit
import SwiftData

struct VideoDetailView: View {
    let video: Video
    @State private var isFavorite: Bool
    @StateObject private var favoritesViewModel: FavoritenViewModel
    @Environment(\.modelContext) private var context
    @StateObject private var historyViewModel = HistoryViewModel()
    @State private var loadError = false
    @Environment(\.colorScheme) private var colorScheme

    init(video: Video, context: ModelContext) {
        self.video = video
        self._isFavorite = State(initialValue: video.isFavorite)
        _favoritesViewModel = StateObject(wrappedValue: FavoritenViewModel(context: context))
    }

    // Baut eine stabile YouTube-Embed-URL aus beliebigen Eingaben (ID, watch-URL, youtu.be)
    private func makeYouTubeEmbedURL(from raw: String) -> URL? {
        // 1. Versuche, die Video-ID mit der bestehenden Methode zu extrahieren
        var id = Video.extractVideoID(from: raw)
        if id.isEmpty {
            // 2. Versuche, die Video-ID direkt aus der URL zu extrahieren
            if let url = URL(string: raw) {
                // a) Prüfe auf v= Query-Parameter (youtube.com/watch?v=)
                if let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let vQuery = comps.queryItems?.first(where: { $0.name == "v" })?.value,
                   !vQuery.isEmpty {
                    id = vQuery
                }
                // b) Prüfe auf youtu.be/<id>
                else if url.host?.contains("youtu.be") == true {
                    let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    if !path.isEmpty {
                        id = path
                    }
                }
                // c) Prüfe auf /embed/<id>
                else if url.path.contains("/embed/") {
                    let parts = url.path.components(separatedBy: "/")
                    if let embedIdx = parts.firstIndex(of: "embed"), parts.count > embedIdx + 1 {
                        id = parts[embedIdx + 1]
                    }
                }
            }
        }
        guard !id.isEmpty else { return nil }
        // Verwende youtube-nocookie.com für mehr Datenschutz
        return URL(string: "https://www.youtube-nocookie.com/embed/\(id)?playsinline=1&rel=0&modestbranding=1")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                if let embedURL = makeYouTubeEmbedURL(from: video.videoURL) {
                    VideoWebView(url: embedURL, loadFailed: $loadError)
                        .frame(height: 200)
                        .cornerRadius(AppTheme.Radius.m)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                                .stroke(AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
                        )
                        .shadow(color: AppTheme.Colors.shadowCard.opacity(0.6), radius: 8, x: 0, y: 4)
                } else {
                    Text("Ungültige Video-URL")
                        .foregroundStyle(AppTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                }

                // Title
                Text(video.title)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(3)

                // Description
                Text(video.description)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                Spacer()
            }
            .padding(AppTheme.Spacing.m)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .navigationTitle("Details")
        .toolbarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await favoritesViewModel.toggleFavorite(video: video)
                        isFavorite = favoritesViewModel.isFavorite(video: video)
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .imageScale(.large)
                        .foregroundStyle(isFavorite ? AppTheme.Colors.accent : AppTheme.Colors.iconSecondary)
                }
                .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
            }
        }
        .alert("Video konnte nicht geladen werden", isPresented: $loadError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Bitte überprüfe deine Internetverbindung oder die Video-URL.")
        }
        .onAppear {
            isFavorite = favoritesViewModel.isFavorite(video: video)
            historyViewModel.addToHistory(
                videoId: video.id.uuidString,
                title: video.title,
                thumbnailURL: video.thumbnailURL,
                context: context
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesDidChange)) { _ in
            isFavorite = favoritesViewModel.isFavorite(video: video)
        }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self, FavoriteMentorEntity.self, WatchHistoryEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return VideoDetailView(
            video: Video(
                id: UUID(),
                title: "Beispielvideo",
                description: "Dies ist eine Beschreibung.",
                thumbnailURL: "https://placehold.co/600x400",
                videoURL: "xyz",
                category: "Motivation"
            ),
            context: container.mainContext
        )
    }
}

// SwiftUI Wrapper für WKWebView zur Einbettung von YouTube-Videos
struct VideoWebView: UIViewRepresentable {
    let url: URL
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Erlaubt die Inline-Wiedergabe, damit der Player im View eingebettet bleibt
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: VideoWebView

        init(_ parent: VideoWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WKWebView Fehler:", error.localizedDescription)
            parent.loadFailed = true
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WKWebView Fehler:", error.localizedDescription)
            parent.loadFailed = true
        }
    }
}
