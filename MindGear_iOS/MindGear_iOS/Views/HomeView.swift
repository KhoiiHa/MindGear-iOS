//
//  HomeView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 04.07.25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Text("👋 Willkommen bei MindGear")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Entdecke Inspiration und stärke deine mentale Gesundheit.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                NavigationLink(destination: VideoListView(context: context)) {
                    Text("Jetzt starten")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Start")
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: FavoriteVideoEntity.self)
        HomeView()
            .modelContainer(container)
    }
}
