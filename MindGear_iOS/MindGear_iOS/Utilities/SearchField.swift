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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // Eingabefeld
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .accessibilityHidden(true)

                TextField("Suche Videos", text: $text)
                    .submitLabel(.search)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .font(AppTheme.Typography.body)
                    .accessibilityLabel("Suche")
                    .accessibilityHint("Eingeben, um Ergebnisse zu filtern.")
                    .onSubmit { onSubmit() }

                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
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

            // Vorschläge (optional)
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
