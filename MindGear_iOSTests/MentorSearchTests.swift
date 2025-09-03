import XCTest
@testable import MindGear_iOS

final class MentorSearchTests: XCTestCase {
    func testFilterMentors() {
        // Given
        let mentors = [
            Mentor(id: "1", name: "Alice", profileImageURL: nil, bio: nil, playlists: nil, socials: nil),
            Mentor(id: "2", name: "Bob", profileImageURL: nil, bio: nil, playlists: nil, socials: nil),
            Mentor(id: "3", name: "Charlie", profileImageURL: nil, bio: nil, playlists: nil, socials: nil)
        ]

        // When & Then
        let all = filterMentors(mentors, query: "   ")
        XCTAssertEqual(all.count, mentors.count, "Leere Suche sollte alle Mentoren zurückgeben")

        let caseInsensitive = filterMentors(mentors, query: "alice")
        XCTAssertEqual(caseInsensitive.map { $0.name }, ["Alice"], "Suche sollte case-insensitive sein")

        let substring = filterMentors(mentors, query: "Li")
        XCTAssertEqual(substring.map { $0.name }, ["Alice"], "Substring-Treffer sollten genügen")
    }
}
