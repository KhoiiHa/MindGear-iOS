import Foundation
import Combine

class SettingsViewModel: ObservableObject {
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

    init() {
        self.username = UserDefaults.standard.string(forKey: Self.usernameKey) ?? ""
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Self.notificationsKey)
    }
}
