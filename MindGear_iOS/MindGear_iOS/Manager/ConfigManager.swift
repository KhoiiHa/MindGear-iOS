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

    static var chrisWillxChannelId: String {
        return getValue(for: "CHRISWILLX_CHANNEL_ID")
    }

    static var jayShettyChannelId: String {
        return getValue(for: "JAYSHETTY_CHANNEL_ID")
    }


    static var shawnRyanPlaylistId: String {
        return getValue(for: "SHAWNRYAN_PLAYLIST")
    }

    static var jayShettyPlaylistId: String {
        return getValue(for: "JAYSHETTY_PLAYLIST")
    }

    static var recommendedPlaylistId: String {
        return getValue(for: "RECOMMENDED_PLAYLIST")
    }

    static var diaryOfACeoPlaylistId: String {
        return getValue(for: "DIARYOFACEO_PLAYLIST")
    }

    static var theoVonPlaylistId: String {
        return getValue(for: "THEOVON_PLAYLIST")
    }

    static var jordanBPetersonPlaylistId: String {
        return getValue(for: "JORDANBPETERSON_PLAYLIST")
    }

    static var simonSinekPlaylistId: String {
        return getValue(for: "SIMONSINEK_PLAYLIST")
    }

    static var shiHengYiPlaylistId: String {
        return getValue(for: "SHIHENGYI_PLAYLIST")
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
