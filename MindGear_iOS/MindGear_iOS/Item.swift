//
//  Item.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 19.05.25.
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
