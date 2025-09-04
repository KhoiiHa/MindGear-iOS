//
//  MentorSearchTests.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.09.25.
//

import XCTest
@testable import MindGear_iOS

final class MentorSearchTests: XCTestCase {

    // Hilfs-Fabrik, damit wir die echten, vollständigen Initializer der App treffen.
    // Passe die Felder an dein Modell an (z. B. falls `imageURL`, `bio` etc. Pflicht sind).
    private func makeMentor(_ name: String) -> Mentor {
        // TODO: Felder ggf. anpassen – wichtig ist, dass alle required-Parameter gesetzt sind.
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
