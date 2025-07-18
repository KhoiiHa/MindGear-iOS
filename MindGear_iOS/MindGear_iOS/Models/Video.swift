//
//  Video.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//


import Foundation

struct Video: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let thumbnailURL: String
    let videoURL: String
    let category: String
    var isFavorite: Bool = false
}

let sampleVideos: [Video] = [
    Video(
        id: UUID(),
        title: "Die Kraft der Achtsamkeit",
        description: "Ein inspirierendes Video über Achtsamkeit im Alltag.",
        thumbnailURL: "https://example.com/thumbnail1.jpg",
        videoURL: "https://youtube.com/watch?v=xyz",
        category: "Achtsamkeit"
    ),
    Video(
        id: UUID(),
        title: "Mentale Stärke entwickeln",
        description: "Tipps und Übungen für mehr mentale Widerstandskraft.",
        thumbnailURL: "https://example.com/thumbnail2.jpg",
        videoURL: "https://youtube.com/watch?v=abc",
        category: "Motivation"
    )
]
