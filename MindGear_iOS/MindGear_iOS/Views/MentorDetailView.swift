//
//  MentorDetailView.swift
//  MindGear_iOS
//
//  Zweck: Detailseite für Mentoren mit API‑Refresh & Favoriten‑Toggle.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Profilkopf, Bio, Social‑Links, verknüpfte Playlists, Favoriten‑Action.
//  Warum? Schlanke UI; Datenbeschaffung & Logik liegen in ViewModels/Services.
//  Testbarkeit: Klare Accessibility‑IDs; Previews optional mit In‑Memory ModelContext.
//  Status: stabil.
//

import SwiftUI
import SwiftData

// Kurzzusammenfassung: Zeigt Mentor‑Profil, Bio & Playlists; aktualisiert aus API; Favoriten‑Button in der Toolbar.

// MARK: - MentorDetailView
// Warum: Präsentiert Mentor‑Profil; ViewModel kapselt Laden/Favoriten/Observer.
@MainActor
struct MentorDetailView: View {
    private var modelContext: ModelContext
    @StateObject var viewModel: MentorViewModel
    @State private var lastUpdated: Date? = nil
    @State private var configPlaylists: [PlaylistInfo] = []

    // MARK: - Helpers
    /// Entfernt ein optionales "[Seed]"‑Präfix für saubere UI‑Titel.
    /// Warum: Seeds sind Datenquelle, aber nicht Teil der Nutzeroberfläche.
    private func cleanSeed(_ s: String) -> String {
        s.replacingOccurrences(of: #"^\[Seed\]\s*"#, with: "", options: [.regularExpression])
    }

    /// Gibt eine relative Zeitangabe zurück (z. B. „vor 2 Std.“).
    /// Warum: Nutzerfreundlicher als starre Datumsstrings.
    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }

    init(mentor: Mentor, context: ModelContext) {
        self.modelContext = context
        _viewModel = StateObject(wrappedValue: MentorViewModel(mentor: mentor, context: context))
    }

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: AppTheme.Spacing.l) {
                // Status: Laden / Fehler
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppTheme.Colors.accent)
                } else if let msg = viewModel.errorMessage {
                    VStack(spacing: AppTheme.Spacing.s) {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.Colors.danger)
                            Text(msg)
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        Button {
                            Task { await viewModel.loadFromAPIIfPossible() }
                        } label: {
                            Text("Erneut laden")
                                .font(AppTheme.Typography.subheadline)
                        }
                    }
                }
                // Inhalte nur anzeigen, wenn ein Mentor vorhanden ist
                if let m = viewModel.mentor {
                    // Profilbild anzeigen
                    if let urlStr = m.profileImageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                                .accessibilityHidden(true)
                            case .failure:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundStyle(AppTheme.Colors.iconSecondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.Colors.accent, lineWidth: 2))
                        .shadow(color: AppTheme.Colors.shadowCard.opacity(0.6), radius: 12, x: 0, y: 6)
                        .accessibilityIdentifier("mentorProfileImage")
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.Colors.accent, lineWidth: 2))
                            .foregroundStyle(AppTheme.Colors.iconSecondary)
                            .shadow(color: AppTheme.Colors.shadowCard.opacity(0.6), radius: 12, x: 0, y: 6)
                            .accessibilityIdentifier("mentorProfileImage")
                            .accessibilityHidden(true)
                    }

                    // Name des Mentors anzeigen
                    Text(cleanSeed(m.name))
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .accessibilityIdentifier("mentorName")

                    // Biografie des Mentors anzeigen
                    if let bio = m.bio {
                        Text(bio)
                            .font(AppTheme.Typography.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .accessibilityIdentifier("mentorBio")
                    }

                    if let ts = lastUpdated {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "clock")
                                .foregroundStyle(AppTheme.Colors.iconSecondary)
                            Text("Aktualisiert \(relative(ts))")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }

                    // Soziale Links anzeigen, falls vorhanden
                    if let socials = m.socials, !socials.isEmpty {
                        HStack(spacing: AppTheme.Spacing.m) {
                            ForEach(socials) { social in
                                if let url = URL(string: social.url) {
                                    Link(destination: url) {
                                        Text(social.platform)
                                            .font(AppTheme.Typography.headline)
                                            .foregroundStyle(AppTheme.Colors.accent)
                                    }
                                }
                            }
                        }
                    } else {
                        // Hinweis, wenn keine Social-Links verfügbar sind
                        Text("Keine Social-Links verfügbar.")
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }

                    Group {
                        let allPlaylists = (m.playlists ?? []) + configPlaylists
                        if !allPlaylists.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                                Text("Playlists")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                ForEach(allPlaylists) { playlist in
                                    NavigationLink(destination: VideoListView(playlistID: playlist.playlistID, context: modelContext)) {
                                        HStack(alignment: .center, spacing: AppTheme.Spacing.m) {
                                            ThumbnailView(urlString: playlist.thumbnailURL ?? "")
                                                .frame(width: 120, height: 68)
                                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(playlist.title)
                                                    .font(AppTheme.Typography.subheadline)
                                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                                    .lineLimit(2)
                                                if !playlist.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                    Text(playlist.subtitle)
                                                        .font(AppTheme.Typography.footnote)
                                                        .foregroundStyle(AppTheme.Colors.textTertiary)
                                                        .lineLimit(2)
                                                }
                                            }
                                            Spacer(minLength: 0)
                                            Image(systemName: "chevron.right")
                                                .font(.footnote)
                                                .foregroundStyle(AppTheme.Colors.iconSecondary)
                                        }
                                        .contentShape(Rectangle())
                                        .accessibilityIdentifier("playlistCell_\(playlist.playlistID)")
                                    }
                                }
                            }
                            .accessibilityIdentifier("playlistSection")
                            .padding(.top)
                            .padding(.horizontal, AppTheme.Spacing.m)
                        } else {
                            Text("Keine Playlists verknüpft.")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }

                    // Link zum YouTube-Kanal des Mentors
                    if let url = URL(string: "https://youtube.com/channel/\(m.id)") {
                        Link("YouTube-Kanal ansehen", destination: url)
                            .padding(.top, 16)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.accent)
                            .accessibilityIdentifier("mentorChannelLink")
                    }
                } else {
                    // Fallback, wenn (noch) kein Mentor vorhanden
                    Text("Keine Mentordaten verfügbar.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
            .accessibilityIdentifier("mentorDetailContent")
        }
        .accessibilityIdentifier("mentorDetailScroll")
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .navigationTitle("Mentor-Profil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Warum: Favorisieren direkt sichtbar – vermeidet versteckte Menüs
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.toggleFavorite()
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite ? AppTheme.Colors.accent : AppTheme.Colors.iconPrimary)
                }
                .accessibilityIdentifier("mentorFavoriteButton")
                .animation(.easeInOut, value: viewModel.isFavorite)
            }
        }
        // Lifecycle: Favoriten‑Observer aktivieren & Daten laden
        .onAppear {
            viewModel.startObservingFavorites()
        }
        .task {
            await viewModel.loadFromAPIIfPossible()
            await loadConfigPlaylists()
        }
        .onChange(of: viewModel.mentor?.name, initial: false) { _, newValue in
            if let new = newValue, !new.isEmpty, !new.hasPrefix("[Seed]") {
                // Hinweis: Nur setzen, wenn echter Name (ohne Seed‑Präfix) ankommt
                lastUpdated = Date()
            }
        }
        .onChange(of: viewModel.mentor?.profileImageURL, initial: false) { _, _ in
            // Profilbild geändert → Zeitstempel aktualisieren (UI‑Hinweis „Aktualisiert …“)
            lastUpdated = Date()
        }
    }

    /// Lädt verknüpfte Playlists aus der Config (App‑Kuratierung) und ergänzt sie zur API‑Liste.
    /// Warum: Robust gegen fehlende API‑Daten; konsistente Anzeige der Playlists.
    private func loadConfigPlaylists() async {
        guard let mentor = viewModel.mentor else { return }
        // Quelle: Config.plist (Single Source of Truth für kuratierte Playlists)
        let ids = ConfigManager.playlists(for: mentor.id)
        var results: [PlaylistInfo] = []
        for pid in ids {
            if let info = try? await APIService.shared.fetchPlaylistInfo(playlistId: pid) {
                results.append(info)
            }
        }
        // UI‑Update auf dem Main‑Thread (State‑Änderung)
        await MainActor.run { self.configPlaylists = results }
    }
}
