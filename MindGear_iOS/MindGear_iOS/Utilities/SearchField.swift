//
//  SearchField.swift
//  MindGear_iOS
//
//  Zweck: Wiederverwendbares Suchfeld mit optionalen Vorschlägen.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Textbindung, Löschen‑Button, Vorschläge horizontal, Accessibility.
//  Warum? Schlanke, einheitliche UX; Debounce & Logik bleiben im ViewModel.
//  Testbarkeit: Klare Accessibility‑IDs & deterministisches Verhalten.
//  Status: stabil.
//
import SwiftUI

// Kurzzusammenfassung: Eingabefeld mit Lupe, Clear‑Button & optionalen horizontalen Vorschlägen.

// MARK: - SearchField
// Warum: Präsentiert Suchfeld kompakt; Vorschläge & Debounce laufen klar getrennt im ViewModel.
struct SearchField: View {
    // Gebundener Suchtext (Debounce im ViewModel via updateSearch(text:))
    @Binding var text: String
    var placeholder: String = "Suche"
    // Optionale Vorschläge (z. B. Verlauf oder Auto‑Suggest)
    var suggestions: [String] = []
    // Aktionen
    var onSubmit: () -> Void = {}
    var onTapSuggestion: (String) -> Void = { _ in }
    // Stabiler Zugriff in UI‑Tests
    var accessibilityIdentifier: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Eingabefeld inkl. Lupe, Text, Clear‑Button
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    .accessibilityHidden(true)

                TextField(placeholder, text: $text)
                    .submitLabel(.search)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .font(.body)
                    .accessibilityLabel("Suche")
                    .accessibilityHint("Eingeben, um Ergebnisse zu filtern.")
                    .accessibilityIdentifier(accessibilityIdentifier ?? "")
                    .accessibilityAddTraits(.isSearchField)
                    .onSubmit { onSubmit() }

                // Clear‑Button erscheint nur, wenn Text vorhanden
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                    }
                    .accessibilityLabel("Suche löschen")
                    .accessibilityHint("Setzt den Suchtext zurück.")
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .frame(height: 44)
            .background(AppTheme.Colors.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.Radius.m)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                    .stroke(AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: AppTheme.Colors.shadowCard.opacity(0.5), radius: 6, y: 3)

            // Horizontale Vorschläge (optional)
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        ForEach(suggestions, id: \.self) { s in
                            Button(s) { onTapSuggestion(s) }
                                .buttonStyle(.bordered)
                                .tint(AppTheme.Colors.accent)
                                .accessibilityHint("Suchvorschlag einsetzen.")
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
                .accessibilityElement(children: .contain)
            }
        }
    }
}


// MARK: - Preview
#Preview("SearchField") {
    @Previewable @State var query: String = ""
    return VStack {
        // Beispiel: mit Vorschlägen & Submit‑Print
        SearchField(
            text: $query,
            placeholder: "Suche Videos",
            suggestions: ["Disziplin", "Fokus", "Mindset"],
            onSubmit: { print("Submit: \(query)") },
            onTapSuggestion: { s in query = s },
            accessibilityIdentifier: "previewSearchField"
        )
        .padding()
        Spacer()
    }
}
