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
    var placeholder: String = NSLocalizedString("search.title", comment: "")
    // Optionale Vorschläge (z. B. Verlauf oder Auto‑Suggest)
    var suggestions: [String] = []
    // Optionaler a11y‑Hint-Key (falls View kontextspezifisch ist)
    var accessibilityHintKey: String? = nil
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
                    .accessibilityLabel(NSLocalizedString("search.title", comment: ""))
                    .accessibilityHint(NSLocalizedString(accessibilityHintKey ?? "search.generic.hint", comment: ""))
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
                    .transition(.opacity.combined(with: .scale))
                    .accessibilityLabel(NSLocalizedString("search.clear", comment: ""))
                    .accessibilityHint(NSLocalizedString("search.clear.hint", comment: ""))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .frame(height: 50)
            .background(AppTheme.Colors.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.Radius.l)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                    .stroke(AppTheme.Colors.cardStroke(for: colorScheme), lineWidth: 1)
            )
            .shadow(color: AppTheme.Colors.shadowCard.opacity(0.35), radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.12), value: text.isEmpty)

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
