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
    var thumbnailURL: String
    var videoURL: String
    var category: String
    var thumbnailData: Data?

    init(id: UUID, title: String, videoDescription: String, thumbnailURL: String, videoURL: String, category: String, thumbnailData: Data? = nil) {
        self.id = id
        self.title = title
        self.videoDescription = videoDescription
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.category = category
        self.thumbnailData = thumbnailData
    }
}
