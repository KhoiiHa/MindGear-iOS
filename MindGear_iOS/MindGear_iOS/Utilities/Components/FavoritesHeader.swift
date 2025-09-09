import SwiftUI

/// Reusable header for the Favorites screen.
/// Provides a filter segmented control and a search field.
struct FavoritesHeader: View {
    @Binding var selectedFilter: FavoriteFilter
    @Binding var searchText: String
    var suggestions: [String]

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // Filter segmented picker
            Picker("Filter", selection: $selectedFilter) {
                Text("Videos").tag(FavoriteFilter.videos)
                Text("Mentoren").tag(FavoriteFilter.mentors)
                Text("Playlists").tag(FavoriteFilter.playlists)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppTheme.Spacing.m)

            // Search field
            SearchField(
                text: $searchText,
                placeholder: NSLocalizedString("search.favorites", comment: ""),
                suggestions: suggestions,
                accessibilityHintKey: "search.generic.hint",
                onSubmit: {},
                onTapSuggestion: { q in searchText = q },
                accessibilityIdentifier: "favoritesSearchField"
            )
            .padding(.horizontal, AppTheme.Spacing.m)
        }
        .padding(.vertical, AppTheme.Spacing.s)
        .background(AppTheme.Colors.headerBackground(for: scheme))
    }
}

#if DEBUG
struct FavoritesHeader_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesHeader(
            selectedFilter: .constant(.videos),
            searchText: .constant(""),
            suggestions: ["Mindset", "Discipline"]
        )
        .preferredColorScheme(.dark)
    }
}
#endif
