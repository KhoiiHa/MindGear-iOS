//
//  VideoDetailView.swift
//  MindGear_iOS
//
//  Zweck: Detailseite für ein Video mit eingebettetem YouTube‑Player, Beschreibung & Favoriten‑Action.
//  Architekturrolle: SwiftUI View (präsentationsnah) + Wrapper für WKWebView.
//  Verantwortung: Player‑Einbettung (privacy‑freundlich), Titel/Beschreibung, „Im Browser öffnen“, Favoriten‑Toggle.
//  Warum? Schlanke UI; Persistenz/History/Favoriten liegen in ViewModels/Services.
//  Testbarkeit: Klare Accessibility‑IDs, deterministisches URL‑Handling.
//  Status: stabil.
//

import SwiftUI
import WebKit
import SwiftData

// Kurzzusammenfassung: Normalisiert YouTube‑IDs → nutzt youtube‑nocookie Embed; zeigt Titel/Beschreibung; Toolbar‑Herz.

// MARK: - VideoDetailView
// Warum: Präsentiert Video‑Details; WebView‑Einbettung ist gekapselt.
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

    /// Normalisiert unterschiedliche Eingaben (ID, watch‑URL, youtu.be, /embed) zu einer privacy‑freundlichen Embed‑URL.
    /// Warum: youtube‑nocookie.com verringert Tracking; `playsinline` & `modestbranding` verbessern UX.
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

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                if let embedURL = makeYouTubeEmbedURL(from: video.videoURL), !loadError {
                    VideoWebView(url: embedURL, loadFailed: $loadError)
                        .frame(height: 200)
                        .cornerRadius(AppTheme.Radius.m)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                                .stroke(AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
                        )
                        .accessibilityIdentifier("videoWebView")
                        .accessibilityHidden(true)
                } else if loadError {
                    ContentUnavailableView(
                        "Video nicht verfügbar",
                        systemImage: "exclamationmark.triangle",
                        description: Text("Dieses Video kann nicht geladen werden. Es könnte privat, blockiert oder entfernt sein.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        VStack(spacing: AppTheme.Spacing.s) {
                            Button("Erneut versuchen") {
                                if let embedURL = makeYouTubeEmbedURL(from: video.videoURL) {
                                    loadError = false
                                    NotificationCenter.default.post(name: .reloadVideoWebView, object: embedURL)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("retryButton")

                            Button("Auf YouTube öffnen") {
                                if let url = URL(string: video.videoURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("openInYouTubeButton")
                        }
                    )
                } else {
                    Text("Ungültige Video-URL")
                        .foregroundStyle(AppTheme.Colors.accent)
                        .frame(maxWidth: .infinity)
                }

                // Title
                Text(video.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("videoTitle")

                // Description
                Text(video.description)
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: 640, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .accessibilityIdentifier("videoDescription")

                // Language notice
                Text("content.languageNotice")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                    .accessibilityIdentifier("videoLanguageNotice")

                Button(action: {
                    if let url = URL(string: video.videoURL) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Im Browser öffnen", systemImage: "safari")
                }
                .buttonStyle(PillButtonStyle())
                .accessibilityIdentifier("detailOpenInBrowserButton")

                Spacer()
            }
            .mgCard()
            .padding(AppTheme.Spacing.m)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.listBackground(for: colorScheme).ignoresSafeArea())
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
                        .font(.title3)
                        .foregroundStyle(isFavorite ? AppTheme.Colors.accent : AppTheme.Colors.iconSecondary)
                        .symbolEffect(.bounce, value: isFavorite)
                }
                .accessibilityIdentifier("favoriteButton")
                .accessibilityLabel(isFavorite ? "Aus Favoriten entfernen" : "Zu Favoriten hinzufügen")
                .accessibilityHint("Favorit umschalten")
                .accessibilityAddTraits(.isButton)
                .contentShape(Rectangle())
            }
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

// MARK: - Preview (legacy Provider)
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

#Preview("Dark Mode") {
    let container = try! ModelContainer(
        for: FavoriteVideoEntity.self, FavoriteMentorEntity.self, WatchHistoryEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        VideoDetailView(
            video: Video(
                id: UUID(),
                title: "Preview: Privacy‑Embed",
                description: "Kurzer Beschreibungstext für die Preview.",
                thumbnailURL: "https://placehold.co/600x400",
                videoURL: "https://youtu.be/dQw4w9WgXcQ",
                category: "Preview"
            ),
            context: container.mainContext
        )
    }.preferredColorScheme(.dark)
}

// MARK: - VideoWebView (WKWebView Wrapper)
/// Betten YouTube‑Videos ein; steuert Reload via Notification.
struct VideoWebView: UIViewRepresentable {
    /// Ziel‑URL (privacy‑freundlich, z. B. youtube‑nocookie)
    let url: URL
    /// Fehlerflag für UI‑Alert bei Ladefehlern
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Warum: Inline‑Wiedergabe → Player bleibt im Kontext der Seite (kein Fullscreen‑Zwang)
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        NotificationCenter.default.addObserver(forName: .reloadVideoWebView, object: nil, queue: .main) { note in
            if let url = note.object as? URL {
                webView.load(URLRequest(url: url))
            }
        }
        return webView
    }

    /// Läd nach, wenn sich die Ziel‑URL ändert.
    /// Warum: Verhindert unnötige Loads; hält State synchron.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    /// Erstellt den Coordinator (Navigation‑Delegate für Fehlerbehandlung).
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: VideoWebView

        init(_ parent: VideoWebView) {
            self.parent = parent
        }

        /// Mappt Ladefehler nach `loadFailed` → UI zeigt Alert
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WKWebView Fehler:", error.localizedDescription)
            parent.loadFailed = true
        }

        /// Mappt Ladefehler nach `loadFailed` → UI zeigt Alert
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WKWebView Fehler:", error.localizedDescription)
            parent.loadFailed = true
        }
    }
}

extension Notification.Name {
    /// Reload‑Signal für die Video‑WebView (z. B. nach „Erneut versuchen“)
    static let reloadVideoWebView = Notification.Name("ReloadVideoWebView")
}
