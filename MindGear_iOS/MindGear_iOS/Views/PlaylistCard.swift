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
            HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
                // Dekoratives Icon – Inhalt steckt in Texten; Screenreader bekommt Label unten
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .padding(.top, 2)
                    .foregroundStyle(AppTheme.Colors.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                AppTheme.Icons.chevronRight
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .padding(.top, 6)
            }
            .padding(.vertical, AppTheme.Spacing.m)
            .padding(.horizontal, AppTheme.Spacing.l)
            .frame(minHeight: 92)
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
