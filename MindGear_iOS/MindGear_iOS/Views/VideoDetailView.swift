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

    init(video: Video, context: ModelContext) {
        self.video = video
        self._isFavorite = State(initialValue: video.isFavorite)
        _favoritesViewModel = StateObject(wrappedValue: FavoritenViewModel(context: context))
    }

    // Baut eine stabile YouTube-Embed-URL aus beliebigen Eingaben (ID, watch-URL, youtu.be)
    private func makeYouTubeEmbedURL(from raw: String) -> URL? {
        let id = Video.extractVideoID(from: raw)
        guard !id.isEmpty else { return nil }
        return URL(string: "https://www.youtube.com/embed/\(id)")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let embedURL = makeYouTubeEmbedURL(from: video.videoURL) {
                    VideoWebView(url: embedURL, loadFailed: $loadError)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    Text("Ungültige Video-URL")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }

                // Title
                Text(video.title)
                    .font(.title)
                    .fontWeight(.bold)

                // Description
                Text(video.description)
                    .font(.body)
                    .foregroundColor(.secondary)

                // Favorite button
                Button(action: {
                    Task {
                        await favoritesViewModel.toggleFavorite(video: video)
                        isFavorite = favoritesViewModel.isFavorite(video: video)
                    }
                }) {
                    HStack {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .gray)
                        Text(isFavorite ? "Als Favorit entfernen" : "Favorit")
                            .foregroundColor(.accentColor)
                    }
                }
                .accessibilityLabel(isFavorite ? "Favorit entfernen" : "Als Favorit speichern")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .animation(.easeInOut, value: isFavorite)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Details")
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
