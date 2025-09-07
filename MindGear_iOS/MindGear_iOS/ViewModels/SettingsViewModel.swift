import Foundation
import Combine

// Verwalten der Einstellungen und Benachrichtigungen
class SettingsViewModel: ObservableObject {
    // MARK: - State
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

    private static let usernameKey = "username"
    private static let notificationsKey = "notificationsEnabled"

    // MARK: - Init
    init() {
        self.username = UserDefaults.standard.string(forKey: Self.usernameKey) ?? ""
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Self.notificationsKey)
    }

    // MARK: - Loading
    /// Synchronizes the notificationsEnabled flag with the actual system authorization status
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
    /// Toggles notifications: requests permission if enabling, opens settings if already denied
    func toggleNotifications() {
        if notificationsEnabled {
            NotificationManager.shared.requestAuthorization { granted in
                self.notificationsEnabled = granted
            }
        } else {
            NotificationManager.shared.openSystemSettings()
        }
    }
}
