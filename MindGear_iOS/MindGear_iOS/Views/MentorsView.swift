//
//  MentorsView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI
import SwiftData
import UIKit

struct MentorsView: View {
    @StateObject private var viewModel = MentorViewModel()
    @State private var searchText = ""
    @State private var refreshID = UUID()
    @State private var displayedMentors: [Mentor] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    // Normalisiert Strings für eine robuste, akzent-insensitive Suche
    private func norm(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }

    // Entfernt ein optionales "[Seed]"-Prefix aus Namen
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

    // Hilfsfunktion, um zu prüfen, ob ein Mentor in den Favoriten ist
    private func isFavorite(_ mentor: Mentor) -> Bool {
        FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: modelContext)
    }


    // Zeigt ein sicheres Avatarbild: lädt nur gültige http/https-URLs, sonst Fallback-Avatar
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
            )
        }
    }

    // Fallback-Avatar mit Initiale im Kreis
    private func fallbackAvatar(letter: Character?) -> some View {
        ZStack {
            Circle().fill(AppTheme.Colors.surfaceElevated)
            Text(letter.map { String($0) } ?? "•")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .clipShape(Circle())
    }

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
            }
        }
        .id(refreshID)
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(AppTheme.listBackground(for: colorScheme))
        .listRowSeparatorTint(AppTheme.Colors.separator)
        // Suchleiste zur Filterung der Mentoren
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Mentoren suchen")
        .tint(AppTheme.Colors.accent)
        .navigationTitle("Mentoren")
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            Task {
                await viewModel.loadAllMentors(seeds: MentorData.allMentors)
                displayedMentors = viewModel.mentors
            }

            let tf = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
            tf.backgroundColor = UIColor(AppTheme.Colors.surface)
            tf.textColor = UIColor(AppTheme.Colors.textPrimary)
            tf.tintColor = UIColor(AppTheme.Colors.accent)
            tf.attributedPlaceholder = NSAttributedString(
                string: "Mentoren suchen",
                attributes: [.foregroundColor: UIColor(AppTheme.Colors.textSecondary)]
            )
        }
        .onChange(of: searchText, initial: false) { _, _ in
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 250_000_000) // 250ms Debounce
                applySearch()
            }
        }
        .onChange(of: viewModel.mentors) { _, _ in
            applySearch()
        }
        .overlay {
            if displayedMentors.isEmpty && !searchText.isEmpty {
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
