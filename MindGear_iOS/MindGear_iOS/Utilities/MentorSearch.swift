import Foundation

/// Filtert eine Liste von Mentoren anhand einer Suchanfrage.
/// - Parameters:
///   - mentors: Ausgangsliste der Mentoren.
///   - query: Suchtext, wird getrimmt und ist case-insensitive.
/// - Returns: Gefilterte Mentor-Liste.
func filterMentors(_ mentors: [Mentor], query: String) -> [Mentor] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return mentors }
    return mentors.filter { mentor in
        mentor.name.range(of: trimmed, options: .caseInsensitive) != nil
    }
}
