import SwiftUI
import SwiftData

@main
struct MindGear_iOSApp: App {
    init() {
        // Configure global URLCache for smoother thumbnail reuse (memory ~50MB, disk ~200MB)
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 200 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, directory: nil)
    }

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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(AppTheme.Colors.accent)
                .preferredColorScheme(.dark) // fixed dark UI to match the app's moodboard
        }
        .modelContainer(sharedModelContainer)
    }
}
