//
//  HistoryView.swift
//  MindGear_iOS
//
//  Zweck: Verlaufsliste („Zuletzt gesehen“) mit Swipe‑to‑Delete & Pull‑to‑Refresh.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Anzeige, relative Datumsformatierung, Löschen & Refresh.
//  Warum? Schlanke UI; Persistenz & Logik liegen im HistoryViewModel/SwiftData.
//  Testbarkeit: Accessibility‑IDs + Previews ermöglichen stabile UI‑Tests.
//  Status: stabil.
//
import SwiftUI
import SwiftData

// Kurzzusammenfassung: Liste mit Thumbnails, Titel & relativer Zeit; Delete via Swipe; Refresh über Pull.

// MARK: - HistoryView
// Warum: Präsentiert Verlaufseinträge; ViewModel kapselt Laden/Entfernen.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // Relative Zeitdarstellung (z. B. "vor 2 Std.")
    private let relativeFormatter: RelativeDateTimeFormatter = {
        // Warum: Nutzerfreundliche Anzeige („vor 2 Std.“) statt starrer Datumsstrings
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    // MARK: - Body
    var body: some View {
        List {
            // Hinweis: `id: .videoId` ist stabil genug, da VideoIDs eindeutig sind
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
                                    .accessibilityHidden(true)
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
                // Warum: Deletion zentral im ViewModel – Persistenz & Notifications dort bündeln
                for index in indices {
                    let entry = viewModel.history[index]
                    viewModel.deleteFromHistory(entry: entry, context: context)
                }
            }
        }
        .accessibilityIdentifier("historyList")
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
        .safeAreaInset(edge: .top) {
            if let msg = viewModel.errorMessage, !msg.isEmpty {
                ErrorBanner(message: msg) {
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.bottom, 8)
                .background(AppTheme.listBackground(for: colorScheme))
                .overlay(Rectangle().fill(AppTheme.Colors.separator).frame(height: 1), alignment: .bottom)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: viewModel.errorMessage)
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

// MARK: - Preview
#Preview {
    do {
        let container = try ModelContainer(
            for: WatchHistoryEntity.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return NavigationStack {
            HistoryView()
                .modelContainer(container)
            HistoryView().preferredColorScheme(.dark)
        }
    } catch {
        return Text("Preview-Fehler: \(error.localizedDescription)")
    }
}
