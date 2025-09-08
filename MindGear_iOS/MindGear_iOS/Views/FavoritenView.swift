//
//  FavoritenView.swift
//  MindGear_iOS
//
//  Zweck: Übersicht & Verwaltung aller Favoriten (Videos, Mentoren, Playlists) mit Suche & Filter.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Segment-Filter, Suchfeld, Liste, Swipe-to-Delete, Navigation.
//  Warum? Schlanke UI; Persistenz/Logik liegt in ViewModels/Services.
//  Testbarkeit: Accessibility-IDs + Previews ermöglichen stabile UI-Tests.
//  Status: stabil.
//
import SwiftUI
import SwiftData

// Kurzzusammenfassung: Segmentierter Filter, lokaler Such-Overlay, gemischte Liste mit Navigation & Delete.

// MARK: - Types
private typealias FavoriteItem = FavoritenViewModel.FavoriteItem

// UI-Filter (Alle/Videos/Mentoren/Playlists) – wirkt nur lokal auf die kombinierte Liste
private enum FavoriteFilter: String, CaseIterable, Identifiable {
    case all = "Alle"
    case videos = "Videos"
    case mentors = "Mentoren"
    case playlists = "Playlists"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .videos: return "play.rectangle.fill"
        case .mentors: return "person.2.fill"
        case .playlists: return "rectangle.stack.fill"
        }
    }
}

// MARK: - Routing
private enum Route: Hashable {
    case mentor(String)    // channelId oder Name
    case playlist(String)  // playlistId
    case video(String)     // videoId
}

struct FavoritenView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FavoritenViewModel
    @State private var searchText: String = ""
    @State private var selectedFilter: FavoriteFilter = .all
    @Environment(\.colorScheme) private var colorScheme
    /// Nutzerfreundliche Fehlermeldung für Banner
    @State private var errorMessage: String? = nil

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: FavoritenViewModel(context: context))
    }

    // MARK: - State (Computed)
    // Vereinheitlichte Quelle: gemischte Favoriten aus dem ViewModel
    private var combinedFavorites: [FavoriteItem] {
        let items = viewModel.allFavorites
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }

    private var videoFavorites: [FavoriteItem] { combinedFavorites.filter { $0.type == .video } }
    private var mentorFavorites: [FavoriteItem] { combinedFavorites.filter { $0.type == .mentor } }
    private var playlistFavorites: [FavoriteItem] { combinedFavorites.filter { $0.type == .playlist } }

    private var filteredFavorites: [FavoriteItem] {
        switch selectedFilter {
        case .all: return combinedFavorites
        case .videos: return videoFavorites
        case .mentors: return mentorFavorites
        case .playlists: return playlistFavorites
        }
    }

    private func count(for f: FavoriteFilter) -> Int {
        switch f {
        case .all: return combinedFavorites.count
        case .videos: return videoFavorites.count
        case .mentors: return mentorFavorites.count
        case .playlists: return playlistFavorites.count
        }
    }

    // Vorschläge aus allen Titeln (Prefix bevorzugt), ohne Duplikate
    private var suggestionItems: [String] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard q.count >= 2 else { return [] }
        let titles = viewModel.allFavorites.map { $0.title }
        let prefix = titles.filter { $0.lowercased().hasPrefix(q) }
        let rest = titles.filter { $0.lowercased().contains(q) && !$0.lowercased().hasPrefix(q) }
        var merged: [String] = []
        for t in (prefix + rest) where !merged.contains(t) { merged.append(t) }
        return Array(merged.prefix(6))
    }

    // MARK: - Subviews (Header)
    // Schlankes Suchfeld über der Liste – Filter passiert lokal via searchText (Warum: schnelle UX ohne API-Kosten)
    private var headerSearch: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FavoriteFilter.allCases) { f in
                    Label {
                        Text("\(f.rawValue) (\(count(for: f)))")
                    } icon: { Image(systemName: f.icon) }
                    .tag(f)
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.Spacing.m)
            .accessibilityIdentifier("favoritesSegmentedControl")
            .overlay(
                HStack(spacing: AppTheme.Spacing.s) {
                    Button("Alle") { selectedFilter = .all }
                        .accessibilityIdentifier("favoritesAllTab")
                    Button("Videos") { selectedFilter = .videos }
                        .accessibilityIdentifier("favoritesVideosTab")
                    Button("Mentoren") { selectedFilter = .mentors }
                        .accessibilityIdentifier("favoritesMentorsTab")
                    Button("Playlists") { selectedFilter = .playlists }
                        .accessibilityIdentifier("favoritesPlaylistsTab")
                }
                .opacity(0.02)
            )

            SearchField(
                text: $searchText,
                placeholder: "Favoriten durchsuchen",
                suggestions: suggestionItems,
                onSubmit: { },
                onTapSuggestion: { s in searchText = s },
                accessibilityIdentifier: "favoritesSearchField"
            )
            .padding(.horizontal, AppTheme.Spacing.m)
            .accessibilityLabel("Suche")
            .accessibilityHint("Eingeben, um Favoriten zu filtern.")
        }
        .padding(.top, AppTheme.Spacing.s)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, systemImage: String, count: Int) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: systemImage)
            Text("\(title) (\(count))")
        }
        .font(AppTheme.Typography.footnote)
        .foregroundStyle(AppTheme.Colors.textSecondary)
        .textCase(nil)
        .padding(.vertical, AppTheme.Spacing.xs)
        .padding(.horizontal, AppTheme.Spacing.m)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Body
    var body: some View {
        List {
            if filteredFavorites.isEmpty {
                ContentUnavailableView(
                    "Keine Favoriten",
                    systemImage: "heart",
                    description: Text("Speichere Videos, Mentoren und Playlists als Favorit, um sie hier zu sehen.")
                )
            } else {
                if selectedFilter == .all {
                    if !videoFavorites.isEmpty {
                        Section {
                            ForEach(videoFavorites, id: \._id) { item in
                                row(for: item)
                                // Warum: Swipe-to-Delete statt versteckter Menüs → klare, erwartbare Interaktion
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) { delete(item: item) } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                        .accessibilityIdentifier("favoritesDeleteButton")
                                        .tint(AppTheme.Colors.danger)
                                    }
                            }
                            .onDelete { idx in deleteFrom(list: videoFavorites, at: idx) }
                        } header: {
                            sectionHeader("Videos", systemImage: "play.rectangle.fill", count: videoFavorites.count)
                        }
                        .headerProminence(.standard)
                        .listRowBackground(AppTheme.listBackground(for: colorScheme))
                    }
                    if !mentorFavorites.isEmpty {
                        Section {
                            ForEach(mentorFavorites, id: \._id) { item in
                                row(for: item)
                                // Warum: Swipe-to-Delete statt versteckter Menüs → klare, erwartbare Interaktion
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) { delete(item: item) } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                        .accessibilityIdentifier("favoritesDeleteButton")
                                        .tint(AppTheme.Colors.danger)
                                    }
                            }
                            .onDelete { idx in deleteFrom(list: mentorFavorites, at: idx) }
                        } header: {
                            sectionHeader("Mentoren", systemImage: "person.2.fill", count: mentorFavorites.count)
                        }
                        .headerProminence(.standard)
                        .listRowBackground(AppTheme.listBackground(for: colorScheme))
                    }
                    if !playlistFavorites.isEmpty {
                        Section {
                            ForEach(playlistFavorites, id: \._id) { item in
                                row(for: item)
                                // Warum: Swipe-to-Delete statt versteckter Menüs → klare, erwartbare Interaktion
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) { delete(item: item) } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                        .accessibilityIdentifier("favoritesDeleteButton")
                                        .tint(AppTheme.Colors.danger)
                                    }
                            }
                            .onDelete { idx in deleteFrom(list: playlistFavorites, at: idx) }
                        } header: {
                            sectionHeader("Playlists", systemImage: "rectangle.stack.fill", count: playlistFavorites.count)
                        }
                        .headerProminence(.standard)
                        .listRowBackground(AppTheme.listBackground(for: colorScheme))
                    }
                } else {
                    ForEach(filteredFavorites, id: \._id) { item in
                        row(for: item)
                        // Warum: Swipe-to-Delete statt versteckter Menüs → klare, erwartbare Interaktion
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { delete(item: item) } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                                .accessibilityIdentifier("favoritesDeleteButton")
                                .tint(AppTheme.Colors.danger)
                            }
                    }
                    .onDelete(perform: deleteFavorite)
                    .listRowBackground(AppTheme.listBackground(for: colorScheme))
                }
            }
        }
        .accessibilityIdentifier("favoritesList")
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .listRowSeparatorTint(AppTheme.Colors.separator)
        .listRowBackground(AppTheme.listBackground(for: colorScheme))
        .listSectionSpacing(.compact)
        .listSectionSeparator(.hidden)
        .navigationTitle("Favoriten")
        .toolbarTitleDisplayMode(.large)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .top) {
            // Warum: Suchfeld bleibt visuell an die Navigation gekoppelt (klare Hierarchie)
            headerSearch
                .background(AppTheme.listBackground(for: colorScheme))
        }
        .safeAreaInset(edge: .top) {
            if let msg = errorMessage, !msg.isEmpty {
                ErrorBanner(message: msg) { errorMessage = nil }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, 8)
                    .background(AppTheme.listBackground(for: colorScheme))
                    .overlay(Rectangle().fill(AppTheme.Colors.separator).frame(height: 1), alignment: .bottom)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: errorMessage)
        // MARK: - Navigation
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .mentor(let id):
                if let mentor = resolveMentor(for: id) {
                    MentorDetailView(mentor: mentor, context: context)
                } else {
                    ContentUnavailableView("Mentor nicht gefunden", systemImage: "person.crop.circle.badge.questionmark")
                }
            case .playlist(let id):
                PlaylistView(playlistId: id, context: context)
            case .video(let id):
                if let video = resolveVideo(for: id) {
                    VideoDetailView(video: video, context: context)
                } else {
                    ContentUnavailableView("Video nicht gefunden", systemImage: "film.stack")
                }
            }
        }
    }

    // MARK: - Row
    @ViewBuilder
    private func row(for item: FavoriteItem) -> some View {
        switch item.type {
        case .video:
            HStack(spacing: AppTheme.Spacing.m) {
                NavigationLink(value: Route.video(item.id)) {
                    HStack(spacing: AppTheme.Spacing.m) {
                        if let urlStr = item.thumbnailURL, let url = URL(string: urlStr) {
                            ThumbnailView(urlString: url.absoluteString, width: 88, height: 56, cornerRadius: AppTheme.Radius.m)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "video")
                                .frame(width: 88, height: 56)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .background(AppTheme.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m))
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(item.title)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Video")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Button(role: .destructive) { delete(item: item) } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("favoritesInlineDelete")
            }
            .contentShape(Rectangle())
            .accessibilityIdentifier("favoriteCell_video_\(item.id)")
            .listRowBackground(AppTheme.listBackground(for: colorScheme))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("Video")
            .accessibilityHint("Doppeltippen, um Details zu öffnen.")
        case .mentor:
            HStack(spacing: AppTheme.Spacing.m) {
                NavigationLink(value: Route.mentor(item.id)) {
                    HStack(spacing: AppTheme.Spacing.m) {
                        if let urlStr = item.thumbnailURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty: AppTheme.Colors.surfaceElevated
                                case .success(let image): image.resizable().scaledToFill()
                                case .failure: Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(AppTheme.Colors.textSecondary)
                                @unknown default: Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(AppTheme.Colors.textSecondary)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .accessibilityHidden(true)
                        } else {
                            Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(AppTheme.Colors.textSecondary)
                                .frame(width: 44, height: 44)
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(item.title)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Mentor")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Button(role: .destructive) { delete(item: item) } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("favoritesInlineDelete")
            }
            .contentShape(Rectangle())
            .accessibilityIdentifier("favoriteCell_mentor_\(item.id)")
            .listRowBackground(AppTheme.listBackground(for: colorScheme))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("Mentor")
            .accessibilityHint("Doppeltippen, um Details zu öffnen.")
        case .playlist:
            HStack(spacing: AppTheme.Spacing.m) {
                NavigationLink(value: Route.playlist(item.id)) {
                    HStack(spacing: AppTheme.Spacing.m) {
                        if let urlStr = item.thumbnailURL, let url = URL(string: urlStr) {
                            ThumbnailView(urlString: url.absoluteString, width: 88, height: 56, cornerRadius: AppTheme.Radius.m)
                                .accessibilityHidden(true)
                        } else {
                            Image(systemName: "rectangle.stack")
                                .frame(width: 88, height: 56)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .background(AppTheme.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m))
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(item.title)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Playlist")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Button(role: .destructive) { delete(item: item) } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("favoritesInlineDelete")
            }
            .contentShape(Rectangle())
            .accessibilityIdentifier("favoriteCell_playlist_\(item.id)")
            .listRowBackground(AppTheme.listBackground(for: colorScheme))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("Playlist")
            .accessibilityHint("Öffnet Playlist.")
        }
    }


    // MARK: - Resolvers
    private func resolveVideo(for id: String) -> Video? {
        // Rekonstruktion aus Favoriten-Entity (enthält alle nötigen Felder)
        // Hinweis: In Favoriten ist `item.id` oft die Entity-UUID; Fallback über `videoURL` erlaubt Navigation
        // (Warum: robust gegen ältere gespeicherte Einträge)
        let all: [FavoriteVideoEntity] = (try? context.fetch(FetchDescriptor<FavoriteVideoEntity>())) ?? []
        if let fav = all.first(where: { String(describing: $0.id) == id || $0.videoURL == id }) {
            return Video(
                id: fav.id,
                title: fav.title,
                description: fav.videoDescription,
                thumbnailURL: fav.thumbnailURL,
                videoURL: fav.videoURL,
                category: fav.category,
                isFavorite: true
            )
        }
        return nil
    }

    // MARK: - Mentor Resolver (Favorites → Mentor model, then Seeds fallback)
    private func resolveMentor(for key: String) -> Mentor? {
        // 1) Try to reconstruct from stored favorites first
        if let fav = mentorFavorite(matching: key) {
            return mentor(from: fav)
        }
        // 2) Fallback to seed data (MentorData)
        if let m1 = MentorData.getMentor(byChannelId: key) { return m1 }
        if let m2 = MentorData.getMentor(byName: key) { return m2 }
        return nil
    }

    /// Try to find a FavoriteMentorEntity by Channel-ID (stored as `id`) or display name
    private func mentorFavorite(matching key: String) -> FavoriteMentorEntity? {
        let all: [FavoriteMentorEntity] = (try? context.fetch(FetchDescriptor<FavoriteMentorEntity>())) ?? []
        // Match by Channel-ID (entity stores YouTube channelId in `id`) or by display name
        return all.first { $0.id == key || $0.name == key }
    }

    private func mentor(from fav: FavoriteMentorEntity) -> Mentor {
        // Optional: enrich from seeds for bio/socials if present
        let seed = MentorData.getMentor(byChannelId: fav.id) ?? MentorData.getMentor(byName: fav.name)
        return Mentor(
            id: fav.id,                                     // your Mentor expects `id:` (channelId)
            name: fav.name,
            profileImageURL: fav.profileImageURL ?? seed?.profileImageURL,
            bio: seed?.bio,
            playlists: seed?.playlists,
            socials: seed?.socials
        )
    }

    // MARK: - Actions (Deletion)
    // Warum: Löschen zentral kapseln; UI-Listen reagieren via .favoritesDidChange
    private func deleteFavorite(at offsets: IndexSet) {
        var toDelete: [any PersistentModel] = []
        for index in offsets {
            let item = combinedFavorites[index]
            switch item.type {
            case .video:
                let all: [FavoriteVideoEntity] = (try? context.fetch(FetchDescriptor<FavoriteVideoEntity>())) ?? []
                if let entity = all.first(where: { String(describing: $0.id) == item.id || $0.videoURL == item.id }) {
                    toDelete.append(entity)
                }
            case .mentor:
                let all: [FavoriteMentorEntity] = (try? context.fetch(FetchDescriptor<FavoriteMentorEntity>())) ?? []
                if let entity = all.first(where: { String(describing: $0.id) == item.id }) {
                    toDelete.append(entity)
                }
            case .playlist:
                let all: [FavoritePlaylistEntity] = (try? context.fetch(FetchDescriptor<FavoritePlaylistEntity>())) ?? []
                if let entity = all.first(where: { String(describing: $0.id) == item.id }) {
                    toDelete.append(entity)
                }
            }
        }
        toDelete.forEach { context.delete($0) }
        do {
            try context.save()
        } catch {
            let ns = error as NSError
            errorMessage = "Favoriten konnten nicht gelöscht werden (\(ns.localizedDescription))."
            #if DEBUG
            print("Save failed (favorite delete):", ns)
            #endif
        }
        // UI informieren: Listen & Badges aktualisieren
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }

    private func deleteFrom(list: [FavoriteItem], at offsets: IndexSet) {
        // Mappt Abschnitts-Indizes korrekt auf die kombinierte Liste
        let ids = offsets.compactMap { list[$0].id }
        let indexes = combinedFavorites.enumerated().compactMap { idx, el in ids.contains(el.id) ? idx : nil }
        deleteFavorite(at: IndexSet(indexes))
    }

    private func delete(item: FavoriteItem) {
        switch item.type {
        case .video:
            let all: [FavoriteVideoEntity] = (try? context.fetch(FetchDescriptor<FavoriteVideoEntity>())) ?? []
            if let entity = all.first(where: { String(describing: $0.id) == item.id || $0.videoURL == item.id }) {
                context.delete(entity)
            }
        case .mentor:
            let all: [FavoriteMentorEntity] = (try? context.fetch(FetchDescriptor<FavoriteMentorEntity>())) ?? []
            if let entity = all.first(where: { String(describing: $0.id) == item.id }) {
                context.delete(entity)
            }
        case .playlist:
            let all: [FavoritePlaylistEntity] = (try? context.fetch(FetchDescriptor<FavoritePlaylistEntity>())) ?? []
            if let entity = all.first(where: { String(describing: $0.id) == item.id }) {
                context.delete(entity)
            }
        }
        do {
            try context.save()
        } catch {
            let ns = error as NSError
            errorMessage = "Favorit konnte nicht gelöscht werden (\(ns.localizedDescription))."
            #if DEBUG
            print("Save failed (favorite delete single):", ns)
            #endif
        }
        // UI informieren (Single-Delete): Konsistentes Refresh der Favoriten-Views
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }
}

// MARK: - Internal Helpers
// Warum: Stabiles `id`-Binding für List/ForEach via `_id`
extension FavoriteItem {
    fileprivate var _id: String { self.id }
}


// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: FavoriteVideoEntity.self,
             FavoriteMentorEntity.self,
             FavoritePlaylistEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        FavoritenView(context: container.mainContext)
    }
}
