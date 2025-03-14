//
//  Favoriten.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import Foundation
import SwiftData

@Model
class Favorite {
    var channel: Channel
    var video: Video
    
    init(channel: Channel, video: Video) {
        self.channel = channel
        self.video = video
    }
}
