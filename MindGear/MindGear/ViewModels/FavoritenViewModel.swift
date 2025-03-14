//
//  FavoritenViewModel.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import Foundation
import SwiftData

class FavoritesViewModel: ObservableObject {
    @Published var favoriteChannels: [Channel] = []
    
    // Hier würdest du die Favoriten speichern (z. B. mit SwiftData oder UserDefaults)
    func loadFavorites() {
        // Beispielhafte Daten laden
        // In einer echten App würdest du diese Daten aus einer persistenten Quelle laden
        self.favoriteChannels = [
            Channel(id: "1", name: "Joe Rogan", description: "Podcast über verschiedene Themen", videos: [
                Video(id: "1", title: "Mental Health for Men", url: "https://youtube.com/video1", thumbnail: "https://youtube.com/thumbnail1", description: "Ein Video über mentale Gesundheit.")
            ]),
            Channel(id: "2", name: "Chris Williamson", description: "Podcast über Persönlichkeitsentwicklung", videos: [
                Video(id: "2", title: "Selbstbewusstsein stärken", url: "https://youtube.com/video2", thumbnail: "https://youtube.com/thumbnail2", description: "Techniken zur Selbstverbesserung.")
            ])
        ]
    }
    
    // Favoriten entfernen (Beispiel)
    func removeFavorite(channel: Channel, video: Video) {
        // Hier würde der Code zum Entfernen des Videos aus den Favoriten kommen
        if let index = favoriteChannels.firstIndex(where: { $0.id == channel.id }) {
            favoriteChannels[index].videos.removeAll { $0.id == video.id }
        }
    }
}
