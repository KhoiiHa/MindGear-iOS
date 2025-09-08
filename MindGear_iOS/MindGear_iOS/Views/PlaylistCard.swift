//
//  PlaylistCard.swift
//  MindGear_iOS
//
//  Zweck: Kompakte Karte zur Navigation in eine Playlist.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Titel/Untertitel/Icon anzeigen, als tappbare Karte mit Navigation agieren.
//  Warum? Schlanke UI; Daten/Logik liegen in ViewModels/Services.
//  Testbarkeit: Klare Accessibility-Labels/IDs; Preview möglich mit In‑Memory ModelContext.
//  Status: stabil.
//

import SwiftUI
import SwiftData

// Kurzzusammenfassung: Tappable Karte (NavigationLink) mit konsistentem AppTheme‑Styling.

// MARK: - PlaylistCard
// Warum: Ganzer Kartenbereich tappbar; klare Hierarchie über AppTheme.
struct PlaylistCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let playlistID: String
    let context: ModelContext

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body
    var body: some View {
        NavigationLink {
            VideoListView(playlistID: playlistID, context: context)
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                // Dekoratives Icon – Inhalt steckt in Texten; Screenreader bekommt Label unten
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                }

                Spacer()

                AppTheme.Icons.chevronRight
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
            }
            .padding(.vertical, AppTheme.Spacing.m)
            .padding(.horizontal, AppTheme.Spacing.l)
            .mgCard()
            .padding(.horizontal)
            .contentShape(Rectangle())
            // Warum: Ganze Karte tappbar, ohne den Standard‑Buttonstil zu erben
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title), \(subtitle)")
            .accessibilityHint("Öffnet Playlist.")
        }
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: WatchHistoryEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        PlaylistCard(
            title: "Mindset Essentials",
            subtitle: "5 Videos · 45 Min",
            iconName: "brain.head.profile",
            playlistID: "PL123456789",
            context: container.mainContext
        )
        .padding()
    }
}
