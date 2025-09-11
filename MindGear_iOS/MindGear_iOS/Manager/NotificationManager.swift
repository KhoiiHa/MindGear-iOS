//
//  NotificationManager.swift
//  MindGear_iOS
//
//  Zweck: Verwaltung lokaler iOS-Benachrichtigungen (UNUserNotificationCenter).
//  Architekturrolle: Service/Manager (Wrapper um iOS Notification APIs).
//  Verantwortung: Berechtigungen abfragen, Settings öffnen, Erinnerungen planen.
//  Warum? Entkoppelt App-Logik von UIKit/UserNotifications; zentrale API für Scheduling.
//  Testbarkeit: Methoden via Dependency-Injection mockbar; Scheduling als no‑op in Tests.
//  Status: vorbereitet für zukünftige Reminder-Features.
//
import Foundation
import UserNotifications
import UIKit

// MARK: - NotificationManager
// Warum: Zentrale Steuerung aller lokalen Notifications; vermeidet Streulogik.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - State
    // Zentraler Zugriff auf das Notification-Center
    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization
    /// Fragt die Berechtigung beim Nutzer an.
    /// Warum: UX‑kritisch – Pushes müssen explizit erlaubt sein; Resultat wird ins UI gespiegelt.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Liefert aktuellen Berechtigungsstatus.
    /// Warum: Views/ViewModels können UI (z. B. Switch) synchron zum Systemstatus halten.
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Navigation
    /// Öffnet die Systemeinstellungen der App.
    /// Warum: Ermöglicht dem Nutzer, Benachrichtigungsrechte manuell nachzuziehen.
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Scheduling
    /// Plant eine tägliche Erinnerung (Platzhalter, ausbaubar).
    /// Warum: Zeigt, wie Scheduling funktioniert; vorbereitet für echte Reminder‑Features.
    func scheduleDailyReminder() {
        // Offene Aufgabe: Autorisierung, Content & Trigger ergänzen, Request planen.
    }
}
