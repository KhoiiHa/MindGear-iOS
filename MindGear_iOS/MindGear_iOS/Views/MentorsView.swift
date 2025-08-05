//
//  MentorsView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//



import SwiftUI

struct MentorsView: View {
    let mentors: [Mentor]

    var body: some View {
        NavigationStack {
            List(mentors) { mentor in
                NavigationLink(destination: MentorDetailView(mentor: mentor)) {
                    HStack {
                        AsyncImage(url: URL(string: mentor.profileImageURL)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        Text(mentor.name)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Mentoren")
        }
    }
}
