//
//  CategoriesView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 29.07.25.
//

import SwiftUI

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

let categories: [Category] = [
    Category(name: "Mindset", icon: "🧠"),
    Category(name: "Disziplin & Fokus", icon: "🥊"),
    Category(name: "Emotionale Intelligenz", icon: "❤️"),
    Category(name: "Beziehungen", icon: "🤝"),
    Category(name: "Innere Ruhe & Achtsamkeit", icon: "🧘"),
    Category(name: "Motivation & Energie", icon: "🔥"),
    Category(name: "Werte & Purpose", icon: "🧭"),
    Category(name: "Impulse & Perspektiven", icon: "🧩")
]

struct CategoriesView: View {
    var body: some View {
        NavigationView {
            List(categories) { category in
                HStack {
                    Text(category.icon)
                        .font(.largeTitle)
                    Text(category.name)
                        .font(.headline)
                        .padding(.leading, 8)
                }
            }
            .navigationTitle("Kategorien")
        }
    }
}

struct CategoriesView_Previews {
    #Preview {
        CategoriesView()
    }
}
