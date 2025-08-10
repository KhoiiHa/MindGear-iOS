//
//  MentorsView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI
import SwiftData

struct MentorsView: View {
    let mentors: [Mentor]
    @State private var searchText = ""
    @State private var refreshID = UUID()
    @Environment(\.modelContext) private var modelContext

    // Hilfsfunktion, um zu prüfen, ob ein Mentor in den Favoriten ist
    private func isFavorite(_ mentor: Mentor) -> Bool {
        FavoritesManager.shared.isMentorFavorite(mentor: mentor, context: modelContext)
    }

    // Gefilterte Liste der Mentoren basierend auf dem Suchtext
    private var filteredMentors: [Mentor] {
        if searchText.isEmpty {
            return mentors
        } else {
            return mentors.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Zeigt ein sicheres Avatarbild: lädt nur gültige http/https-URLs, sonst Fallback-Avatar
    private func avatarView(for mentor: Mentor) -> some View {
        let raw = mentor.profileImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
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
                        Color.gray.opacity(0.15)
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
            Circle().fill(Color.gray.opacity(0.15))
            Text(letter.map { String($0) } ?? "•")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .clipShape(Circle())
    }

    var body: some View {
        // Navigation Stack für die Navigation zwischen Ansichten
        NavigationStack {
            // Liste der gefilterten Mentoren
            List(filteredMentors) { mentor in
                NavigationLink(destination: MentorDetailView(mentor: mentor, context: modelContext)
                    .onDisappear {
                        refreshID = UUID()
                    }
                ) {
                    HStack {
                        // Avatar mit sicherem Fallback (kein endloses Laden)
                        avatarView(for: mentor)
                        // Anzeige des Mentorennamens
                        Text(mentor.name)
                            .font(.headline)
                        // Herz-Symbol, wenn der Mentor in den Favoriten ist
                        if isFavorite(mentor) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .id(refreshID)
            // Suchleiste zur Filterung der Mentoren
            .searchable(text: $searchText, prompt: "Mentor suchen")
            .navigationTitle("Mentoren")
        }
    }
}
