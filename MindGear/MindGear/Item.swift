//
//  Item.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
