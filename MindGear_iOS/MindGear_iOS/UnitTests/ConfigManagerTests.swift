//
//  ConfigManagerTests.swift
//  MindGear_iOS
//
//  Zweck: UnitTests für ConfigManager (Config.plist Werte, Basis‑URL & PlaylistID).
//  Architekturrolle: XCTestCase (UnitTest‑Layer).
//  Verantwortung: Prüft Validität & Integrität zentraler Config‑Werte.
//  Warum? Fehlerhafte Config‑Werte führen zu Ladefehlern; Tests sichern korrekte Defaults.
//  Testbarkeit: Deterministisch via Config.plist.
//  Status: stabil.
//

import XCTest
@testable import MindGear_iOS
// Kurzzusammenfassung: Testet apiBaseURL() (HTTPS, Host, Pfad) & recommendedPlaylistId (nicht leer).

// MARK: - ConfigManagerTests
/// UnitTests für die zentralen ConfigManager‑Werte.
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
