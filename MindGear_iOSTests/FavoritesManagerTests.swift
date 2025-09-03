import XCTest
@testable import MindGear_iOS

@MainActor
final class FavoritesManagerTests: XCTestCase {
    private let testID = "test-id"
    private var manager: FavoritesManager!

    override func setUp() {
        super.setUp()
        manager = FavoritesManager()
        // Clean state
        manager.all().forEach { manager.remove($0) }
    }

    func testToggleAndPersistence() {
        // Given
        XCTAssertFalse(manager.isFavorite(testID), "ID sollte anfangs kein Favorit sein")

        // When
        manager.toggle(testID)

        // Then
        XCTAssertTrue(manager.isFavorite(testID), "Toggle sollte ID hinzufügen")

        // When
        manager.toggle(testID)

        // Then
        XCTAssertFalse(manager.isFavorite(testID), "Erneutes Toggle sollte ID entfernen")

        // Given
        manager.toggle(testID)
        // When
        let secondInstance = FavoritesManager()
        // Then
        XCTAssertTrue(secondInstance.isFavorite(testID), "Favoriten sollten über Instanzen hinweg erhalten bleiben")
    }
}
