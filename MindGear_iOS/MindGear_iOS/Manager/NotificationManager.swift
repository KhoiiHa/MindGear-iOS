import Foundation
import UserNotifications
import UIKit

/// Handles notification scheduling. Currently contains stubs for upcoming features.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// Requests notification authorization from the user.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Retrieves the current notification authorization status.
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    /// Opens the system settings for the app so the user can manage notification permissions.
    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    /// Once permissions have been granted, this will schedule a daily local notification reminder.
    /// - Note: Implementation will be added in a later ticket.
    func scheduleDailyReminder() {
        // TODO: Request authorization and schedule notification
    }
}
