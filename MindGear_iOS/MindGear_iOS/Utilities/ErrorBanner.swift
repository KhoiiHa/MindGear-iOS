//
//  ErrorBanner.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 08.09.25.
//

//
//  ErrorBanner.swift
//  MindGear_iOS
//
//  Zweck: Einheitliche UI-Komponente für Fehlermeldungen.
//  Architekturrolle: Reusable View (Utilities).
//  Verantwortung: Zeigt dezente Hinweise bei Fehlern oder Warnungen an.
//  Warum? Konsistente UX, klare Kommunikation von Problemen, ohne User-Flow zu blockieren.
//

import SwiftUI

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.medium)
                .foregroundColor(.red)
                .padding(.top, 2)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Button(action: { onDismiss?() }) {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.red.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fehler")
        .accessibilityValue(message)
    }
}

#Preview {
    ErrorBanner(message: "API-Key fehlt – bitte Einstellungen prüfen.") { }
        .padding()
}
