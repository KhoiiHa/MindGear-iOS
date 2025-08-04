//
//  PlaylistInfo.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.08.25.
//

import Foundation

struct PlaylistInfo: Identifiable {
    var id: String { playlistID } // Für ForEach
    let title: String
    let subtitle: String
    let iconName: String
    let playlistID: String
}
