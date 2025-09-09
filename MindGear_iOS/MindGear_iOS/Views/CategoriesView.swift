//
//  CategoriesView.swift
//  MindGear_iOS
//
//  Zweck: Übersicht aller Kategorien mit Suche und Navigation zur Detailansicht.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Listendarstellung, Suchfilter, Navigation.
//  Warum? Schlanke UI, Logik (Filter) bleibt lokal, Datenmodell extern.
//  Testbarkeit: Previews + klare Accessibility-Ziele möglich.
//  Status: stabil.
//

import SwiftUI
import UIKit

// Kurzzusammenfassung: Grid/Stack-ähnliche Kategorie-Liste mit lokalem Suchfilter und systemkonformer Navigation.

// Übersicht aller Kategorien
struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText: String = ""

    // Lokalfilter: Case-insensitiv, matches Name oder Icon
    private var filteredCategories: [Category] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return categories }
        return categories.filter { cat in
            let q = searchText.lowercased()
            return cat.name.lowercased().contains(q) || cat.icon.lowercased().contains(q)
        }
    }

    // MARK: - Body
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
                                    .font(.title)
                                    .padding(.trailing, AppTheme.Spacing.s)
                                Text(category.name)
                                    .font(.body)
                                    .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
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
            .scrollIndicators(.hidden)
            .background(AppTheme.listBackground(for: colorScheme))
            .toolbar {
            // Warum: Titel in der Mitte für klares visuelles Hierarchiesignal
                ToolbarItem(placement: .principal) {
                    Text("Kategorien")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Kategorien suchen")
            .tint(AppTheme.Colors.accent)
            .onAppear {
                // Styling der UISearchBar: an AppTheme angleichen (Portfolio: konsistentes Look&Feel)
                let tf = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
                tf.backgroundColor = UIColor(AppTheme.Colors.surface)
                tf.textColor = UIColor(AppTheme.textPrimary(for: colorScheme))
                tf.tintColor = UIColor(AppTheme.Colors.accent)
                tf.attributedPlaceholder = NSAttributedString(
                    string: "Kategorien suchen",
                    attributes: [.foregroundColor: UIColor(AppTheme.textSecondary(for: colorScheme))]
                )
            }
        }
        // MARK: - Styling
        .background(AppTheme.Colors.background)
    }
}


