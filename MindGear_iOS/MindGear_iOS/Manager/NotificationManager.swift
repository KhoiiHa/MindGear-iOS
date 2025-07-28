import Foundation
import UserNotifications

/// Handles notification scheduling. Currently contains stubs for upcoming features.
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    /// Requests permission and schedules a local notification.
    /// - Note: Implementation will be added in a later ticket.
    func scheduleDailyReminder() {
        // TODO: Request authorization and schedule notification
    }
}
