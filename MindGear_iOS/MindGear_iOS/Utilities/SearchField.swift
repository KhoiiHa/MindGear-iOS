import SwiftUI

/// Schlankes, wiederverwendbares Suchfeld für Listenansichten.
/// - MVVM‑freundlich: Der Text wird gebunden; Debounce passiert im ViewModel.
/// - Optional: horizontale Vorschläge (z. B. Verlauf oder Auto‑Suggest).
struct SearchField: View {
    // Gebundener Suchtext (Debounce im ViewModel über updateSearch(text:))
    @Binding var text: String

    // Optional angezeigte Vorschläge (z. B. Verlauf)
    var suggestions: [String] = []

    // Aktionen
    var onSubmit: () -> Void = {}
    var onTapSuggestion: (String) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Eingabefeld
            TextField("Suche Videos", text: $text)
                .submitLabel(.search)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .accessibilityLabel("Suche")
                .accessibilityHint("Eingeben, um Ergebnisse zu filtern.")
                .onSubmit { onSubmit() }

            // Vorschläge (optional)
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { s in
                            Button(s) { onTapSuggestion(s) }
                                .buttonStyle(.bordered)
                                .accessibilityHint("Suchvorschlag einsetzen.")
                        }
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityElement(children: .contain)
            }
        }
    }
}

// MARK: - Preview (nur für Entwicklung)
#Preview("SearchField") {
    @Previewable @State var query: String = ""
    return VStack {
        SearchField(
            text: $query,
            suggestions: ["Disziplin", "Fokus", "Mindset"],
            onSubmit: { print("Submit: \(query)") },
            onTapSuggestion: { s in query = s }
        )
        .padding()
        Spacer()
    }
}
