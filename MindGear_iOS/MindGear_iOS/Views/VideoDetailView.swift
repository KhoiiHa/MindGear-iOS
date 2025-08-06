import SwiftUI
import WebKit
import SwiftData

struct VideoDetailView: View {
    let video: Video
    @State private var isFavorite: Bool
    @StateObject private var favoritesViewModel = FavoritenViewModel()
    @State private var loadError = false
    @Environment(\.modelContext) private var context

    init(video: Video) {
        self.video = video
        self._isFavorite = State(initialValue: video.isFavorite)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let url = URL(string: video.videoURL) {
                    VideoWebView(url: url, loadFailed: $loadError)
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
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

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
            favoritesViewModel.context = context
            isFavorite = favoritesViewModel.isFavorite(video: video)
        }
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(video: Video(
            id: UUID(),
            title: "Beispielvideo",
            description: "Dies ist eine Beschreibung.",
            thumbnailURL: "https://placehold.co/600x400",
            videoURL: "https://youtube.com/watch?v=xyz",
            category: "Motivation"
        ))
    }
}

struct VideoWebView: UIViewRepresentable {
    let url: URL
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
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
            parent.loadFailed = true
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loadFailed = true
        }
    }
}
