//
//  FavoriteVideoEntity.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 07.07.25.
//

import Foundation
import SwiftData

@Model
final class FavoriteVideoEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var videoDescription: String
    var thumbnailURL: URL
    var videoURL: URL
    var category: String

    init(id: UUID, title: String, videoDescription: String, thumbnailURL: URL, videoURL: URL, category: String) {
        self.id = id
        self.title = title
        self.videoDescription = videoDescription
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.category = category
    }
}
