import SwiftUI
import SwiftData

/// Einfache Verlaufsliste ("Zuletzt gesehen").
/// Zeigt gespeicherte `WatchHistoryEntity`‑Einträge, sortiert nach Datum.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HistoryViewModel()

    // Relative Zeitdarstellung (z. B. "vor 2 Std.")
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    var body: some View {
        List {
            ForEach(viewModel.history, id: \.videoId) { entry in
                HStack(spacing: 12) {
                    // Thumbnail (einfach & robust)
                    if let url = URL(string: entry.thumbnailURL), url.scheme?.hasPrefix("http") == true {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Color.gray.opacity(0.15)
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "photo")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 80, height: 60)
                        .cornerRadius(8)
                    } else {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 60)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(relativeFormatter.localizedString(for: entry.watchedAt, relativeTo: Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
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
        .navigationTitle("Verlauf")
        .toolbar { EditButton() }
        .overlay {
            if viewModel.history.isEmpty {
                ContentUnavailableView(
                    "Noch kein Verlauf",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Gesehene Videos erscheinen hier.")
                )
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
