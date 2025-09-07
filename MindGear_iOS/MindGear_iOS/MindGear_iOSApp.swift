//
//  MindGear_iOSApp.swift
//  MindGear_iOS
//
//  Zweck: Einstiegspunkt der App (App Lifecycle).
//  Architekturrolle: @main App (Composition Root).
//  Verantwortung: Initialisierung von SwiftData‑Container, URLCache & Root‑Navigation.
//  Warum? Zentrale Stelle für globale Konfigurationen; Onboarding‑Flow entscheidet über Start‑Screen.
//  Testbarkeit: Indirekt über UI‑Tests; Debug‑Argumente (z. B. -resetOnboarding) vereinfachen Test‑Flows.
//  Status: stabil.
//
import SwiftUI
import SwiftData
// Kurzzusammenfassung: Initialisiert URLCache, SwiftData Container & schaltet zwischen Onboarding/MainTab.

@main
struct MindGear_iOSApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    // MARK: - Init
    /// Konfiguriert globalen URLCache & verarbeitet Debug‑Argumente (z. B. Onboarding reset).
    init() {
        // Configure global URLCache for smoother thumbnail reuse (memory ~50MB, disk ~200MB)
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 200 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, directory: nil)
        
        if CommandLine.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        }
    }

    // MARK: - SwiftData Container
    /// Gemeinsamer SwiftData‑Container mit allen Entities; Fallback: In‑Memory für Debug/Previews.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FavoriteVideoEntity.self,
            FavoriteMentorEntity.self,
            FavoritePlaylistEntity.self,
            WatchHistoryEntity.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            assertionFailure("❌ Failed to create ModelContainer: \(error)")
            // Fallback: use an in-memory store so the app remains usable in Debug/Previews
            let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Unrecoverable ModelContainer error: \(error)")
            }
        }
    }()

    // MARK: - Scene
    /// Root‑Scene: Entscheidet zwischen Onboarding & MainTabView.
    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .onAppear {
                if UserDefaults.standard.object(forKey: "hasSeenOnboarding") == nil {
                    hasSeenOnboarding = false
                }
            }
            .tint(AppTheme.Colors.accent)
            .preferredColorScheme(.dark) // fixed dark UI to match the app's moodboard
        }
        .modelContainer(sharedModelContainer)
    }
}
