//
//  SettingsView.swift
//  MindGear_iOS
//
//  Zweck: Einstellungen für Profil, Benachrichtigungen und Onboarding-Reset.
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Form-Abschnitte (Profil/Benachrichtigungen/Verlauf/Demo), Navigation & Alerts.
//  Warum? Schlanke UI; System-/Persistenzdetails liegen im ViewModel/Services.
//  Testbarkeit: Klare Accessibility-IDs; Preview vorhanden.
//  Status: stabil.
//
import SwiftUI

// Kurzzusammenfassung: Form mit Profilfeld, Notification-Toggle (mit Status-Sync), Verlauf-Link und Onboarding-Reset.

// MARK: - SettingsView
// Warum: Präsentiert App-Einstellungen; ViewModel kapselt Persistenz & System-Abfragen.
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showResetAlert = false

    // MARK: - Body
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
                        // Warum: Username lokal editierbar; Persistenz via ViewModel (UserDefaults)
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
                    .toggleStyle(.switch)
                    // Statuswechsel → Flow im ViewModel: Permission anfragen oder Settings öffnen
                    .onChange(of: viewModel.notificationsEnabled, initial: false) { _, _ in
                        viewModel.toggleNotifications()
                    }
                    // UI-Tests: stabiler Zugriff auf den Toggle
                    .accessibilityIdentifier("notificationsToggle")
                    .accessibilityHint("Schalte Benachrichtigungen an oder aus")
                } header: {
                    Text("Benachrichtigungen")
                        .font(AppTheme.Typography.subtitle)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .listRowBackground(AppTheme.Colors.surface)

                Section {
                    // Warum: Verlauf als eigener Screen – Verantwortlichkeiten trennen
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

                Section {
                    // Demo-Action: Onboarding-Flag zurücksetzen (zeigt Sequenz beim nächsten Start)
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.Colors.accent.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.Colors.accent)
                            }
                            Text("Onboarding zurücksetzen")
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                        }
                    }
                    .accessibilityIdentifier("resetOnboardingButton")
                    .alert("Onboarding wirklich zurücksetzen?", isPresented: $showResetAlert) {
                        Button("Abbrechen", role: .cancel) {}
                        Button("Zurücksetzen", role: .destructive) {
                            // Single Source of Truth: AppStorage-Flag zurücksetzen
                            hasSeenOnboarding = false
                        }
                    } message: {
                        Text("Beim nächsten Start wird das Onboarding erneut angezeigt.")
                    }
                } header: {
                    Text("Demo")
                        .font(AppTheme.Typography.subtitle)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .listRowBackground(AppTheme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.listBackground(for: colorScheme))
            .tint(AppTheme.Colors.primary)
            .navigationTitle("Einstellungen")
            .accessibilityIdentifier("settingsScreen")
            .toolbarBackground(.visible, for: .navigationBar)
            // Lifecycle: Beim Öffnen einmalig den echten System-Status der Notifications spiegeln
            .onAppear {
                viewModel.syncNotificationStatus()
            }
        }
        .preferredColorScheme(.dark)
    }
}

