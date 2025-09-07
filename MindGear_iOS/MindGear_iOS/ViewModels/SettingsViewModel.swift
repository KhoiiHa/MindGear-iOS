//
//  SettingsViewModel.swift
//  MindGear_iOS
//
//  Zweck: UI‑Zustand & Logik für die Einstellungen (Username, Notifications).
//  Architekturrolle: ViewModel (MVVM).
//  Verantwortung: Persistenz via UserDefaults, Sync mit NotificationManager, Toggle‑Intents.
//  Warum? Entkoppelt Views von System‑/Persistenzdetails; sorgt für deterministisches UI‑Binding.
//  Testbarkeit: UserDefaults resetbar; NotificationManager via Protokoll mockbar.
//  Status: stabil.
//

import Foundation
import Combine

// MARK: - Implementierung: SettingsViewModel
// Warum: Zentralisiert Settings‑State; erleichtert UI‑Tests & Wiederverwendung.
class SettingsViewModel: ObservableObject {
    // MARK: - State
    // Persistenz: UserDefaults – sofortige Synchronisierung bei didSet
    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: Self.usernameKey)
        }
    }
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Self.notificationsKey)
        }
    }

    // Schlüssel in UserDefaults (Single Source of Truth)
    private static let usernameKey = "username"
    private static let notificationsKey = "notificationsEnabled"

    // MARK: - Init
    // Lädt initialen Zustand aus UserDefaults
    init() {
        self.username = UserDefaults.standard.string(forKey: Self.usernameKey) ?? ""
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Self.notificationsKey)
    }

    // MARK: - Loading
    /// Synchronisiert `notificationsEnabled` mit dem echten System‑Authorization‑Status.
    /// Warum: UI soll konsistent mit den iOS‑Systemeinstellungen bleiben.
    func syncNotificationStatus() {
        NotificationManager.shared.getAuthorizationStatus { status in
            switch status {
            case .authorized, .provisional:
                self.notificationsEnabled = true
            default:
                self.notificationsEnabled = false
            }
        }
    }

    // MARK: - Actions
    /// Wechselt Notifications: fragt Berechtigung an, wenn aktiviert; öffnet Settings, wenn abgelehnt.
    /// Warum: UX‑freundlicher Flow, kein stilles Scheitern.
    func toggleNotifications() {
        if notificationsEnabled {
            // Anfrage: Permission anfordern → Callback aktualisiert Flag
            NotificationManager.shared.requestAuthorization { granted in
                self.notificationsEnabled = granted
            }
        } else {
            // Bereits abgelehnt: Nutzer in Systemeinstellungen leiten
            NotificationManager.shared.openSystemSettings()
        }
    }
}
