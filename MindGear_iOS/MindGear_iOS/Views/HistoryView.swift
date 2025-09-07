import SwiftUI
import SwiftData

/// Einfache Verlaufsliste ("Zuletzt gesehen").
/// Zeigt gespeicherte `WatchHistoryEntity`‑Einträge, sortiert nach Datum.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // Relative Zeitdarstellung (z. B. "vor 2 Std.")
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    // MARK: - UI
    var body: some View {
        List {
            ForEach(viewModel.history, id: \.videoId) { entry in
                HStack(spacing: AppTheme.Spacing.m) {
                    // Thumbnail (einfach & robust)
                    if let url = URL(string: entry.thumbnailURL), url.scheme?.hasPrefix("http") == true {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                AppTheme.Colors.surfaceElevated
                            case .success(let image):
                                image.resizable().scaledToFill()
                                    .cornerRadius(AppTheme.Radius.m)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            @unknown default:
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                        }
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m))
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .frame(width: 80, height: 60)
                            .background(AppTheme.Colors.surfaceElevated)
                            .cornerRadius(AppTheme.Radius.m)
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(entry.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text(relativeFormatter.localizedString(for: entry.watchedAt, relativeTo: Date()))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .onDelete { indices in
                for index in indices {
                    let entry = viewModel.history[index]
                    viewModel.deleteFromHistory(entry: entry, context: context)
                }
            }
        }
        .refreshable {
            viewModel.loadHistory(context: context)
        }
        .tint(AppTheme.Colors.accent)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .listRowSeparatorTint(AppTheme.Colors.separator)
        .navigationTitle("Verlauf")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar { EditButton() }
        .overlay {
            if viewModel.history.isEmpty {
                ContentUnavailableView(
                    "Noch kein Verlauf",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Gesehene Videos erscheinen hier.")
                )
                .padding()
            }
        }
        .onAppear {
            viewModel.loadHistory(context: context)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: WatchHistoryEntity.self)
        return NavigationStack {
            HistoryView()
                .modelContainer(container)
        }
    } catch {
        return Text("Preview-Fehler: \(error.localizedDescription)")
    }
}
