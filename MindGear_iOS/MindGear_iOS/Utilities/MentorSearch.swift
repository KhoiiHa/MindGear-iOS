//
//  MentorSearch.swift
//  MindGear_iOS
//
//  Zweck: Hilfsfunktion zum Filtern von Mentoren nach Suchtext.
//  Architekturrolle: Utility (Business-nah, aber UI-unabhängig).
//  Verantwortung: String-Matching (case-/whitespace-insensitiv).
//  Warum? Saubere Trennung: ViewModels rufen nur diese Logik auf, statt selbst zu filtern.
//  Testbarkeit: Pure Function → deterministisch, leicht unit-testbar.
//  Status: stabil.
//
import Foundation

// Kurzzusammenfassung: Filtert Mentorenliste anhand Name + Query (case-insensitiv, getrimmt).

/// Filtert eine Liste von Mentoren anhand einer Query.
/// - Parameter mentors: Ausgangsliste aller Mentoren.
/// - Parameter query: Suchtext, getrimmt & case-insensitiv.
/// - Returns: Gefilterte Liste (enthält nur Mentoren, deren `name` die Query enthält).
/// Warum: Einfache, pure Matching-Logik → vermeidet Boilerplate in ViewModels.
func filterMentors(_ mentors: [Mentor], query: String) -> [Mentor] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return mentors }
    return mentors.filter { mentor in
        mentor.name.range(of: trimmed, options: .caseInsensitive) != nil
    }
}
