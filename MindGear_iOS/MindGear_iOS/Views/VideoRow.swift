//
//  VideoRow.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 01.08.25.
//



import SwiftUI

struct VideoRow: View {
    let video: Video

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let url = URL(string: video.thumbnailURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 70)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 70)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(video.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}
