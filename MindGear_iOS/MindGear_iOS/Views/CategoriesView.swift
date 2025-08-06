//
//  CategoriesView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List(categories) { category in
                NavigationLink {
                    CategoryDetailView(category: category, modelContext: modelContext)
                } label: {
                    HStack {
                        Text(category.icon)
                            .font(.largeTitle)
                        Text(category.name)
                            .font(.headline)
                            .padding(.leading, 8)
                    }
                }
            }
            .navigationTitle("Kategorien")
        }
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesView()
    }
}
