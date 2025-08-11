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
                
                Section(header: Text("Verlauf")) {
                    NavigationLink(destination: HistoryView()) {
                        Label("Verlauf", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
            .navigationTitle("Einstellungen")
        }
    }
}

#Preview {
    SettingsView()
}
