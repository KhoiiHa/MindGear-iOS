import SwiftUI
import SwiftData

// Zugriff auf den im ViewModel definierten Item-Typ
private typealias FavoriteItem = FavoritenViewModel.FavoriteItem

struct FavoritenView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel: FavoritenViewModel
    @State private var searchText: String = ""

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

    var body: some View {
        List {
            if combinedFavorites.isEmpty {
                ContentUnavailableView("Keine Favoriten", systemImage: "heart", description: Text("Speichere Videos, Mentoren und Playlists als Favorit, um sie hier zu sehen."))
            } else {
                ForEach(combinedFavorites, id: \.id) { item in
                    row(for: item)
                }
                .onDelete(perform: deleteFavorite)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Favoriten")
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
            ForEach(suggestionItems, id: \.self) { s in
                Text(s).searchCompletion(s)
            }
        }
    }

    @ViewBuilder
    private func row(for item: FavoriteItem) -> some View {
        switch item.type {
        case .video:
            HStack(spacing: 12) {
                if let urlStr = item.thumbnailURL, let url = URL(string: urlStr) {
                    ThumbnailView(urlString: url.absoluteString, width: 88, height: 56, cornerRadius: 8)
                } else {
                    Image(systemName: "video")
                        .frame(width: 88, height: 56)
                        .foregroundStyle(.secondary)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.headline).lineLimit(2)
                    Text("Video").font(.caption).foregroundStyle(.secondary)
                }
            }
        case .mentor:
            HStack(spacing: 12) {
                if let urlStr = item.thumbnailURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty: Color.gray.opacity(0.12)
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(.secondary)
                        @unknown default: Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.headline).lineLimit(2)
                    Text("Mentor").font(.caption).foregroundStyle(.secondary)
                }
            }
        case .playlist:
            NavigationLink(value: item.id) {
                HStack(spacing: 12) {
                    if let urlStr = item.thumbnailURL, let url = URL(string: urlStr) {
                        ThumbnailView(urlString: url.absoluteString, width: 88, height: 56, cornerRadius: 8)
                    } else {
                        Image(systemName: "rectangle.stack")
                            .frame(width: 88, height: 56)
                            .foregroundStyle(.secondary)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline).lineLimit(2)
                        Text("Playlist").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
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
}
