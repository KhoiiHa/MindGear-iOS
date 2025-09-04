//
//  FavoritesManagerTests.swift
//  MindGear_iOSTests
//
//  Created by Vu Minh Khoi Ha on 04.09.25.
//

import XCTest
@testable import MindGear_iOS

final class FavoritesManagerTests: XCTestCase {

    private var sut: FavoritesManager! // System Under Test

    override func setUp() {
        super.setUp()
        // Use the default initializer from production code
        sut = FavoritesManager()
        // Ensure a clean state before each test using the public API
        sut.all().forEach { sut.remove($0) }
    }

    override func tearDown() {
        // Clean up after each test to avoid cross‑test pollution
        sut.all().forEach { sut.remove($0) }
        sut = nil
        super.tearDown()
    }

    func test_toggle_addsAndRemovesFavorite() {
        let id = "video-123"

        sut.toggle(id)
        XCTAssertTrue(sut.isFavorite(id), "Nach erstem toggle() sollte \(id) als Favorit markiert sein.")

        sut.toggle(id)
        XCTAssertFalse(sut.isFavorite(id), "Nach zweitem toggle() sollte \(id) wieder entfernt sein.")
    }

    func test_all_returnsExactlyAddedIDs() {
        let ids = ["a", "b", "c"]
        ids.forEach { sut.toggle($0) }

        let all = sut.all()
        XCTAssertEqual(Set(all), Set(ids), "all() sollte exakt die hinzugefügten IDs zurückgeben (Reihenfolge egal).")
    }

    func test_persistence_betweenInstances() {
        let id = "persist-999"
        sut.toggle(id)

        // New instance should see the same persisted favorites
        let sut2 = FavoritesManager()
        XCTAssertTrue(sut2.isFavorite(id), "Favoriten müssen zwischen Instanzen/Starts bestehen bleiben.")

        // cleanup the id to not leak into other tests
        sut2.remove(id)
    }
}
