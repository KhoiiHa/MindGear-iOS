//
//  CategoriesView.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.08.25.
//

import SwiftUI
import UIKit

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText: String = ""

    private var filteredCategories: [Category] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return categories }
        return categories.filter { cat in
            let q = searchText.lowercased()
            return cat.name.lowercased().contains(q) || cat.icon.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.s) {
                    ForEach(filteredCategories) { category in
                        NavigationLink {
                            CategoryDetailView(category: category, modelContext: modelContext)
                        } label: {
                            HStack {
                                Text(category.icon)
                                    .font(AppTheme.Typography.title)
                                    .padding(.trailing, AppTheme.Spacing.s)
                                Text(category.name)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                            }
                            .padding(AppTheme.Spacing.m)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                                    .fill(AppTheme.Colors.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m, style: .continuous)
                                    .stroke(AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
                            )
                            .shadow(color: AppTheme.Colors.shadowCard.opacity(0.6), radius: 8, x: 0, y: 4)
                            .contentShape(Rectangle())
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, AppTheme.Spacing.s)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.background)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Kategorien")
                        .font(AppTheme.Typography.title)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Kategorien suchen")
            .tint(AppTheme.Colors.accent)
            .onAppear {
                let tf = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
                tf.backgroundColor = UIColor(AppTheme.Colors.surface)
                tf.textColor = UIColor(AppTheme.Colors.textPrimary)
                tf.tintColor = UIColor(AppTheme.Colors.accent)
                tf.attributedPlaceholder = NSAttributedString(
                    string: "Kategorien suchen",
                    attributes: [.foregroundColor: UIColor(AppTheme.Colors.textSecondary)]
                )
            }
        }
        .background(AppTheme.Colors.background)
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesView()
    }
}
