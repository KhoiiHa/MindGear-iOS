//
//  CategoryData.swift
//  MindGear_iOS
//
//  Zweck: Statische Kategorien (Name + Icon) für die thematische Strukturierung.
//  Architekturrolle: Data Seed (UI‑nah, aber ohne Logik).
//  Verantwortung: Bereitstellung einer fixen Liste von Hauptkategorien.
//  Warum? Einheitliche UX; klare Struktur; kein doppelter String‑Einsatz in Views.
//  Testbarkeit: Deterministisch; Liste kann leicht in Tests verifiziert werden.
//  Status: stabil.
//

import Foundation
// Kurzzusammenfassung: 8 Kernkategorien mit Namen & Emoji‑Icon – als Data Seed für Views.

// MARK: - Category Model
/// Einfache Kategorie mit UUID, Name & Icon.
struct Category: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

// MARK: - Static Seed Data
/// Feste Liste der Hauptkategorien für Onboarding, Filter & Navigation.
let categories: [Category] = [
    Category(name: "Mindset", icon: "🧠"),
    Category(name: "Disziplin & Fokus", icon: "🥊"),
    Category(name: "Emotionale Intelligenz", icon: "❤️"),
    Category(name: "Beziehungen", icon: "🤝"),
    Category(name: "Innere Ruhe & Achtsamkeit", icon: "🧘"),
    Category(name: "Motivation & Energie", icon: "🔥"),
    Category(name: "Werte & Purpose", icon: "🧭"),
    Category(name: "Impulse & Perspektiven", icon: "🧩")
]
