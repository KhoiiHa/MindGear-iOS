//
//  UIStyles.swift
//  MindGear_iOS
//
//  Zweck: Zentrale ViewModifier/ButtonStyles für konsistentes Look & Feel.
//  Architekturrolle: Utility (präsentationsnah).
//  Verantwortung: Card‑Look, Pill‑Buttons; Erweiterung für `.mgCard()`.
//  Warum? Schlanke Wiederverwendung statt dupliziertem Styling in Views.
//  Testbarkeit: Deterministische Werte → Snapshots/UITests leicht prüfbar.
//  Status: stabil.
//

import SwiftUI

// Kurzzusammenfassung: Globale Styles (Cards, Buttons) – nutzen AppTheme Tokens für Einheitlichkeit.

// MARK: - MGCard
/// Einheitlicher Karten‑Look für Listen & Detail‑Elemente.
/// Warum: Vermeidet Stil‑Drift & harte Werte.
struct MGCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            // Subtile Schattenebene – sorgt für Tiefe, ohne zu dominieren
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Convenience‑Extension für Views → `.mgCard()` statt Modifier manuell anzuwenden.
    func mgCard() -> some View { modifier(MGCard()) }
}

// MARK: - PillButtonStyle
/// Abgerundeter Primär‑Button (Capsule‑Look).
/// Warum: Hebt wichtige CTAs hervor; nutzt AppTheme Tokens.
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.body.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(configuration.isPressed
                               ? AppTheme.Colors.accent.opacity(0.85)
                               : AppTheme.Colors.accent)
            )
            .foregroundStyle(Color.white)
            // Kurze Press‑Animation → fühlbares Feedback
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        Text("Card Example").mgCard()
        Button("Primary Action") {}
            .buttonStyle(PillButtonStyle())
    }
    .padding()
}
