import SwiftUI
import SwiftData

// Zugriff auf den im ViewModel definierten Item-Typ
private typealias FavoriteItem = FavoritenViewModel.FavoriteItem

struct FavoritenView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FavoritenViewModel
    @State private var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: FavoritenViewModel(context: context))
    }

    // Vereinheitlichte Quelle: gemischte Favoriten aus dem ViewModel
    private var combinedFavorites: [FavoriteItem] {
        let items = viewModel.allFavorites
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }

    // Vorschläge aus allen Titeln, ohne Duplikate
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

    // Schlankes Suchfeld über der Liste – Filter passiert lokal via searchText
    private var headerSearch: some View {
        SearchField(
            text: $searchText,
            suggestions: suggestionItems,
            onSubmit: { /* optional: nothing to do, Filter ist lokal */ },
            onTapSuggestion: { s in
                // Vorschlag einsetzen und Liste filtern
                searchText = s
            }
        )
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.s)
        .accessibilityLabel("Suche")
        .accessibilityHint("Eingeben, um Favoriten zu filtern.")
    }

    var body: some View {
        List {
            if combinedFavorites.isEmpty {
                ContentUnavailableView("Keine Favoriten", systemImage: "heart", description: Text("Speichere Videos, Mentoren und Playlists als Favorit, um sie hier zu sehen."))
            } else {
                ForEach(combinedFavorites, id: \.id) { item in
                    row(for: item)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(item: item)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        .tint(AppTheme.Colors.danger)
                    }
                }
                .onDelete(perform: deleteFavorite)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .scrollIndicators(.hidden)
        .navigationTitle("Favoriten")
        .toolbarTitleDisplayMode(.large)
        .toolbarBackground(AppTheme.tabBarBackground(for: colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .top) {
            headerSearch
                .background(AppTheme.listBackground(for: colorScheme))
        }
    }

    @ViewBuilder
    private func row(for item: FavoriteItem) -> some View {
        switch item.type {
        case .video:
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("Video")
            .accessibilityHint("Doppeltippen, um Details zu öffnen.")
        case .mentor:
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("Mentor")
            .accessibilityHint("Doppeltippen, um Details zu öffnen.")
        case .playlist:
            NavigationLink(value: item.id) {
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("Playlist")
            .accessibilityHint("Öffnet Playlist.")
        }
    }

    private func deleteFavorite(at offsets: IndexSet) {
        var toDelete: [any PersistentModel] = []
        for index in offsets {
            let item = combinedFavorites[index]
            switch item.type {
            case .video:
                let all: [FavoriteVideoEntity] = (try? context.fetch(FetchDescriptor<FavoriteVideoEntity>())) ?? []
                if let entity = all.first(where: { String(describing: $0.id) == item.id }) {
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
        do { try context.save() } catch { print("Save failed (favorite delete):", error) }
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }

    private func delete(item: FavoriteItem) {
        switch item.type {
        case .video:
            let all: [FavoriteVideoEntity] = (try? context.fetch(FetchDescriptor<FavoriteVideoEntity>())) ?? []
            if let entity = all.first(where: { String(describing: $0.id) == item.id }) {
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
        do { try context.save() } catch { print("Save failed (favorite delete single):", error) }
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }
}
