//
//  MentorSearchTests.swift
//  MindGear_iOSTests
//
//  Zweck: UnitTests für die Filterlogik von Mentoren.
//  Architekturrolle: XCTestCase (UnitTest‑Layer).
//  Verantwortung: Prüft Trimmen, Case‑Insensitivity & Substring‑Matching.
//  Warum? Sichert korrekte Suchergebnisse unabhängig von Groß-/Kleinschreibung & Leerzeichen.
//  Testbarkeit: Deterministisch mit Dummy‑Mentoren.
//  Status: stabil.
//

import XCTest
@testable import MindGear_iOS
// Kurzzusammenfassung: Testet, dass filterMentors korrekt trimmt, case‑insensitive arbeitet und Substrings findet.

// MARK: - MentorSearchTests
/// UnitTests für die Mentor‑Suchlogik.
final class MentorSearchTests: XCTestCase {

    // Hilfs-Fabrik, damit wir die echten, vollständigen Initializer der App treffen.
    // Passe die Felder an dein Modell an (z. B. falls `imageURL`, `bio` etc. Pflicht sind).
    private func makeMentor(_ name: String) -> Mentor {
        // Platzhalter: Zusätzliche Modellfelder bei Bedarf ergänzen.
        return Mentor(
            id: "id-\(name.lowercased())",
            name: name,
            playlists: [] // oder ein Dummy-Array, falls nicht optional
        )
    }

    func test_filter_trimsAndIsCaseInsensitive() {
        let mentors = [makeMentor("Carol"), makeMentor("Alice"), makeMentor("Bob")]

        let result = filterMentors(mentors, query: "  car ")
        let names = result.map(\.name)

        XCTAssertEqual(names, ["Carol"])
    }

    func test_filter_emptyQuery_returnsAll() {
        let mentors = [makeMentor("Carol"), makeMentor("Alice")]
        let result = filterMentors(mentors, query: "")
        XCTAssertEqual(result.count, mentors.count, "Leerer Query sollte alle Mentoren liefern.")
    }

    func test_filter_substringMatch_works() {
        let mentors = [makeMentor("Martin"), makeMentor("Marta"), makeMentor("Anne")]
        let result = filterMentors(mentors, query: "art")
        let names = result.map(\.name)

        XCTAssertEqual(Set(names), Set(["Martin", "Marta"]))
    }
}
