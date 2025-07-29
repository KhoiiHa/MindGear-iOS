//
//  PlaylistView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 29.07.25.
//



import SwiftUI

struct PlaylistView: View {
    var body: some View {
        NavigationStack {
            Text("🎵 Playlist Übersicht kommt bald!")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
                .navigationTitle("Playlisten")
        }
    }
}

#Preview {
    PlaylistView()
}
