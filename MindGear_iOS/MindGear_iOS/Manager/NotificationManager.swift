import Foundation
import UserNotifications
import UIKit

// Verwalten lokaler Benachrichtigungen der App
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - State
    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization
    /// Fragt die Berechtigung beim Nutzer an
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Liefert aktuellen Berechtigungsstatus
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Navigation
    /// Öffnet Systemeinstellungen für Rechte
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Scheduling
    /// Platzhalter für tägliche Erinnerung
    func scheduleDailyReminder() {
        // TODO: Request authorization and schedule notification
    }
}
