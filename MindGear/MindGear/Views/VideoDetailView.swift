//
//  VideoDetailView.swift
//  MindGear
//
//  Created by Vu Minh Khoi Ha on 14.03.25.
//

import SwiftUI
import WebKit

struct VideoDetailView: View {
    var video: Video  // Das Video wird an diese View übergeben

    var body: some View {
        VStack {
            Text(video.title)
                .font(.title)
                .padding()

            Text(video.description ?? "Keine Beschreibung verfügbar.")
                .padding()

            // WebView zum Abspielen des YouTube-Videos
            WebView(url: URL(string: "https://www.youtube.com/embed/\(video.url)")!)
                .frame(height: 250)  // Optional: Setze eine feste Höhe für das Video
        }
        .navigationTitle(video.title)
        .padding()
    }
}

struct WebView: UIViewRepresentable {
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct VideoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VideoDetailView(video: Video(id: "1", title: "Mental Health for Men", url: "https://youtube.com/video1", thumbnail: "https://youtube.com/thumbnail1", description: "Ein Video über mentale Gesundheit."))
    }
}
