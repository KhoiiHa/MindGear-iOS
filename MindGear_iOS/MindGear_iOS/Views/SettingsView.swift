import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primary.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.primary)
                        }
                        TextField("Benutzername", text: $viewModel.username)
                            .textInputAutocapitalization(.words)
                            .font(AppTheme.Typography.body)
                            .tint(AppTheme.Colors.primary)
                    }
                } header: {
                    Text("Profil")
                        .font(AppTheme.Typography.subtitle)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .listRowBackground(AppTheme.Colors.surface)

                Section {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.Colors.secondary.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.secondary)
                            }
                            Text("Aktivieren")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                        }
                    }
                    .tint(AppTheme.Colors.primary)
                } header: {
                    Text("Benachrichtigungen")
                        .font(AppTheme.Typography.subtitle)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .listRowBackground(AppTheme.Colors.surface)

                Section {
                    NavigationLink {
                        HistoryView()
                            .navigationTitle("Verlauf")
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.Colors.primary.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.primary)
                            }
                            Text("Verlauf")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.6))
                        }
                    }
                } header: {
                    Text("Verlauf")
                        .font(AppTheme.Typography.subtitle)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .listRowBackground(AppTheme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(
                AppTheme.Colors.background
                    .ignoresSafeArea()
            )
            .tint(AppTheme.Colors.primary)
            .navigationTitle("Einstellungen")
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SettingsView()
}
