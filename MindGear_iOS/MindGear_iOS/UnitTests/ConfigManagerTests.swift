//
//  ConfigManagerTests.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.09.25.
//

import XCTest
@testable import MindGear_iOS

final class ConfigManagerTests: XCTestCase {

    func test_apiBaseURL_isValidHTTPS() throws {
        // Erwartet: Eine valide https-URL
        let url = try XCTUnwrap(ConfigManager.apiBaseURL(), "apiBaseURL() darf nicht nil sein.")
        XCTAssertEqual(url.scheme?.lowercased(), "https", "apiBaseURL() soll https verwenden.")
        XCTAssertNotNil(url.host, "apiBaseURL() muss einen Host besitzen.")
        // Robust: kein Pfad/Slash am Ende (statt nur hasSuffix("/"))
        XCTAssertTrue(url.path.isEmpty, "apiBaseURL() sollte ohne Pfad/abschließenden Slash zurückkehren.")
    }

    func test_recommendedPlaylistId_isNotEmpty() {
        // Erwartet: ein nicht-leerer String aus der Config
        let id = ConfigManager.recommendedPlaylistId
        XCTAssertFalse(
            id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "recommendedPlaylistId darf nicht leer sein – bitte Config.plist prüfen."
        )
    }
}
