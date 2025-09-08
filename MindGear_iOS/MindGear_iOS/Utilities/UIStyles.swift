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
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let strokeColor: Color = {
            // Dezenter Rahmen – hell/dunkel angepasst
            if scheme == .dark { return Color.white.opacity(0.06) }
            else { return Color.black.opacity(0.06) }
        }()
        let shadowColor: Color = {
            // Ruhiger Schatten, im Dark Mode schwächer
            if scheme == .dark { return Color.black.opacity(0.06) }
            else { return Color.black.opacity(0.10) }
        }()

        return content
            .padding(AppTheme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous))
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
            .font(.body.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, 10)
            .frame(minHeight: 44) // Touch‑Target ≥44pt
            .background(
                Capsule().fill(configuration.isPressed
                               ? AppTheme.Colors.accent.opacity(0.85)
                               : AppTheme.Colors.accent)
            )
            .foregroundStyle(Color.white)
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .hoverEffect(.highlight)
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
