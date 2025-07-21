//
//  ConfigManager.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 21.07.25.
//



import Foundation

struct ConfigManager {
    static var apiKey: String {
        return getValue(for: "API_KEY")
    }

    static var playlistId: String {
        return getValue(for: "PLAYLIST_ID")
    }

    private static func getValue(for key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let value = dict[key] as? String else {
            fatalError("❌ Config Key '\(key)' not found in Config.plist")
        }
        return value
    }
}
