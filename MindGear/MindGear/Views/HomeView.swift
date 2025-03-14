//
//  ContentView.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import SwiftUI

struct HomeView: View {
    let channels: [Channel]  // Hier kannst du deine Channel-Daten einfügen

    var body: some View {
        NavigationView {
            List(channels) { channel in
                Section(header: Text(channel.name)) {
                    ForEach(channel.videos) { video in
                        NavigationLink(destination: VideoDetailView(video: video)) {
                            Text(video.title)  // Video-Titel wird angezeigt
                        }
                    }
                }
            }
            .navigationTitle("YouTube Kanäle")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(channels: [
            Channel(id: "1", name: "Joe Rogan", description: "Beschreibung...", videos: [
                Video(id: "1", title: "Mental Health for Men", url: "https://youtube.com/video1", thumbnail: "https://youtube.com/thumbnail1", description: "Ein Video über mentale Gesundheit.")
            ])
        ])
    }
}
