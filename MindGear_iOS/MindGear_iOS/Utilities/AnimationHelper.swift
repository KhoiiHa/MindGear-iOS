//
//  AnimationHelper.swift
//  MindGear_iOS
//
//  Zweck: Zentrale Sammlung leichter Animations‑Presets für konsistentes UI‑Verhalten.
//  Architekturrolle: Utility (präsentationsnah, keine Geschäftslogik).
//  Verantwortung: Benannte Standardanimationen für Views/Transitions bereitstellen.
//  Warum? Einheitlicher Look & Feel; vermeidet „Magic Numbers“ in Views.
//  Testbarkeit: Deterministische Werte → leicht in Snapshots/UITests zu berücksichtigen.
//  Status: stabil.
//
import SwiftUI

// Kurzzusammenfassung: Benannte Presets (Fade, QuickBounce) für wiederkehrende UI‑Bewegungen.

// MARK: - AnimationHelper (Presets)
/// Sammlung benannter Animationen für konsistente Verwendung in der App.
enum AnimationHelper {
    /// Standard‑Fade für Ein-/Ausblendungen (Listen, Overlays, kleine Zustandswechsel).
    /// Warum: Dezente Wahrnehmung ohne Ablenkung; 300ms ist ein guter Default.
    static let fade: Animation = .easeInOut(duration: 0.3)

    /// Kurzes Feder‑Feedback (Buttons/Batches).
    /// Warum: Hebt Interaktionen hervor, ohne zu verspielt zu wirken.
    static let quickBounce: Animation = .spring(response: 0.25, dampingFraction: 0.7)
}
