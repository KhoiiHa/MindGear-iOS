//
//  MentorsView.swift
//  MindGear_iOS
//
//  Zweck: Mentorenliste mit Suche & Favoriten-Indikator.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Suchfeld, gefilterte Liste, Navigation zur Detailansicht.
//  Warum? Schlanke UI; Datenbeschaffung & Logik liegen im MentorViewModel/Services.
//  Testbarkeit: Klare Accessibility-IDs; Preview mit In‑Memory ModelContainer.
//  Status: stabil.
//

import SwiftUI
// Kurzzusammenfassung: Debouncte Suche, sichere Avatare mit Fallback, Herz bei Favoriten, Navigation zu Details.
import SwiftData

// MARK: - MentorsView
// Warum: Präsentiert Mentoren übersichtlich; ViewModel kapselt Laden/Favoriten.
struct MentorsView: View {
    @StateObject private var viewModel = MentorViewModel()
    @State private var searchText = ""
    @State private var refreshID = UUID()
    @State private var displayedMentors: [Mentor] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var firstLoad: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    // MARK: - Subviews (Header)
    // Eigene Suchleiste (statt .searchable) mit stabiler Accessibility-ID
    private var headerSearch: some View {
        SearchField(
            text: $searchText,
            placeholder: "Mentoren suchen",
            suggestions: [],
            onSubmit: {
                applySearch()
            },
            onTapSuggestion: { suggestion in
                // no suggestions in this screen yet; keep hook for future
            },
            accessibilityIdentifier: "mentorSearchField"
        )
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, AppTheme.Spacing.s)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSearchField)
        .accessibilityLabel("Mentoren suchen")
        .accessibilityHint("Tippe, um Mentoren zu suchen")
        .accessibilityIdentifier("mentorSearchField")
        .accessibilityValue(searchText)
    }

    // MARK: - Helpers
    /// Normalisiert Strings (diakritik-insensitiv, case-folded) für robuste Suche.
    private func norm(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }

    /// Entfernt ein optionales "[Seed]"-Präfix aus Namen (nur Anzeige).
    private func cleanSeed(_ s: String) -> String {
        s.replacingOccurrences(of: #"^\[Seed\]\s*"#, with: "", options: [.regularExpression])
    }

    // Wendet die Suche auf die Quellliste an und aktualisiert die Anzeige
    @MainActor
    private func applySearch() {
        let q = norm(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !q.isEmpty else {
            displayedMentors = viewModel.mentors
            return
        }
        displayedMentors = viewModel.mentors.filter { m in
            let name = norm(cleanSeed(m.name))
            let idNorm = norm(m.id)
            let bio = norm(m.bio ?? "")
            return name.contains(q) || idNorm.contains(q) || bio.contains(q)
        }
    }

    /// Schneller Favoriten-Check für Badges/Toggles (UI-Binding).
    private func isFavorite(_ mentor: Mentor) -> Bool {
        FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: modelContext)
    }

    /// Avatar mit sicherem Fallback (nur http/https laden; sonst Initialen).
    /// Warum: Verhindert endloses Laden/gebrochene Bilder; stabil in Listen.
    private func avatarView(for mentor: Mentor) -> some View {
        let raw = mentor.profileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        // Nur laden, wenn eine echte http/https-URL vorliegt
        if let url = URL(string: raw), let scheme = url.scheme, scheme.hasPrefix("http") {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .accessibilityHidden(true)
                    case .failure(_):
                        fallbackAvatar(letter: mentor.name.first)
                    case .empty:
                        // Dezenter Platzhalter statt ewigem Spinner
                        AppTheme.Colors.surfaceElevated
                    @unknown default:
                        // Zukunftssicher: unbekannte Phasen zeigen den Fallback-Avatar
                        fallbackAvatar(letter: mentor.name.first)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            )
        } else {
            // Ungültige oder leere URL → Fallback
            return AnyView(
                fallbackAvatar(letter: mentor.name.first)
                    .frame(width: 50, height: 50)
                    .accessibilityHidden(true)
            )
        }
    }

    /// Fallback-Avatar mit Initiale.
    /// Warum: Liefert stets sichtbaren Platzhalter ohne Netzwerkkosten.
    private func fallbackAvatar(letter: Character?) -> some View {
        ZStack {
            Circle().fill(AppTheme.Colors.surfaceElevated)
            Text(letter.map { String($0) } ?? "•")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .clipShape(Circle())
    }

    // MARK: - Body
    var body: some View {
        // Liste der gefilterten Mentoren
        List(displayedMentors, id: \.id) { mentor in
            NavigationLink(destination: MentorDetailView(mentor: mentor, context: modelContext)
                .onDisappear {
                    refreshID = UUID()
                }
            ) {
                HStack(spacing: AppTheme.Spacing.m) {
                    // Avatar mit sicherem Fallback (kein endloses Laden)
                    avatarView(for: mentor)
                    // Anzeige des Mentorennamens
                    Text(cleanSeed(mentor.name))
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    // Herz-Symbol, wenn der Mentor in den Favoriten ist
                    if isFavorite(mentor) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("mentorCell_\(mentor.id)")
        }
        .accessibilityIdentifier("mentorsList")
        .id(refreshID)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .listRowSeparatorTint(AppTheme.Colors.separator)
        .safeAreaInset(edge: .top) {
            // Warum: Suchfeld bleibt visuell an die Navigation gekoppelt (klare Hierarchie)
            headerSearch
                .padding(.bottom, 8)
                .background(AppTheme.listBackground(for: colorScheme))
                .overlay(Rectangle().fill(AppTheme.Colors.separator).frame(height: 1), alignment: .bottom)
        }
        .navigationTitle("Mentoren")
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            // Initial-Load: Seeds laden, dann anzeigen (responsiv)
            Task { @MainActor in
                firstLoad = true
                await viewModel.loadAllMentors(seeds: MentorData.allMentors)
                displayedMentors = viewModel.mentors
                firstLoad = false
            }
        }
        .onChange(of: searchText, initial: false) { _, _ in
            // Debounce ~250ms: verhindert teure Filterung beim schnellen Tippen
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000) // 250ms Debounce
                applySearch()
            }
        }
        .onChange(of: viewModel.mentors) { _, _ in
            applySearch()
        }
        // MARK: - Refresh
        .refreshable {
            await viewModel.loadAllMentors(seeds: MentorData.allMentors)
            await MainActor.run { applySearch() }
        }
        // MARK: - Empty/Loading States
        .overlay(alignment: .center) {
            if firstLoad && displayedMentors.isEmpty {
                ProgressView("Lade Mentoren…")
                    .padding()
            } else if displayedMentors.isEmpty && !searchText.isEmpty {
                ContentUnavailableView(
                    "Keine Treffer",
                    systemImage: "magnifyingglass",
                    description: Text("Passe den Suchbegriff an.")
                )
            }
        }
        .animation(.default, value: displayedMentors)
        .onDisappear {
            searchTask?.cancel()
        }
    }
}
// MARK: - Preview
#Preview {
    let container = try! ModelContainer(
        for: FavoriteMentorEntity.self,
            FavoriteVideoEntity.self,
            FavoritePlaylistEntity.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return NavigationStack {
        MentorsView()
            .modelContext(container.mainContext)
    }
}
