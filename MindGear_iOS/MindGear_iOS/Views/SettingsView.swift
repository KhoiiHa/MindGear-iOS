import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profil")) {
                    TextField("Benutzername", text: $viewModel.username)
                }

                Section(header: Text("Benachrichtigungen")) {
                    Toggle("Aktivieren", isOn: $viewModel.notificationsEnabled)
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}
