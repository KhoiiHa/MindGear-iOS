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
    // MARK: - Properties
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
                        TextField(NSLocalizedString("settings.username.placeholder", comment: ""), text: $viewModel.username)
                            .textInputAutocapitalization(.words)
                            .font(.body)
                            .tint(AppTheme.Colors.primary)
                            .accessibilityIdentifier("settings.username") // UI-Test Hook
                    }
                } header: {
                    SectionHeader(title: "settings.section.profile")
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
                            Text(NSLocalizedString("settings.notifications.enable", comment: ""))
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        }
                    }
                    .tint(AppTheme.Colors.primary)
                    .toggleStyle(.switch)
                    // Statuswechsel → Flow im ViewModel: Permission anfragen oder Settings öffnen
                    .onChange(of: viewModel.notificationsEnabled, initial: false) { _, _ in
                        viewModel.toggleNotifications()
                    }
                    // UI-Tests: stabiler Zugriff auf den Toggle
                    .accessibilityIdentifier("notificationsToggle") // UI-Test Hook
                    .accessibilityHint(NSLocalizedString("a11y.notifications.toggle.hint", comment: ""))
                } header: {
                    SectionHeader(title: "settings.section.notifications")
                }
                .listRowBackground(AppTheme.Colors.surface)

                Section {
                    // Warum: Verlauf als eigener Screen – Verantwortlichkeiten trennen
                    NavigationLink {
                        HistoryView()
                            .navigationTitle(LocalizedStringKey("history.title"))
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
                            Text(NSLocalizedString("history.title", comment: ""))
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary(for: colorScheme).opacity(0.6))
                        }
                    }
                } header: {
                    SectionHeader(title: "settings.section.history")
                }
                .listRowBackground(AppTheme.Colors.surface)

                // MARK: - Info
                Section {
                    HStack {
                        Text(NSLocalizedString("settings.about.version", comment: ""))
                            .font(.body)
                            .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        Spacer()
                        Text("\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
                            .foregroundStyle(AppTheme.textSecondary(for: colorScheme))
                            .monospacedDigit()
                            .accessibilityIdentifier("settings.version.label") // UI-Test Hook
                    }
                    // Warum: Version & Build zeigen Release-Reife transparent
                } header: {
                    SectionHeader(title: "settings.section.about")
                }
                .listRowBackground(AppTheme.Colors.surface)

                Section {
                    // Demo/Test-Shortcut: Onboarding neu triggern
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
                            Text(NSLocalizedString("settings.onboarding.reset", comment: ""))
                                .font(.body)
                                .foregroundStyle(AppTheme.textPrimary(for: colorScheme))
                        }
                    }
                    .accessibilityIdentifier("resetOnboardingButton") // UI-Test Hook
                    .alert(NSLocalizedString("settings.onboarding.reset.alert.title", comment: ""), isPresented: $showResetAlert) {
                        Button(NSLocalizedString("action.cancel", comment: ""), role: .cancel) {}
                        Button(NSLocalizedString("settings.onboarding.reset.alert.confirm", comment: ""), role: .destructive) {
                            // Single Source of Truth: AppStorage-Flag zurücksetzen
                            hasSeenOnboarding = false
                        }
                    } message: {
                        Text(NSLocalizedString("settings.onboarding.reset.alert.message", comment: ""))
                    }
                } header: {
                    SectionHeader(title: "settings.section.demo")
                }
                .listRowBackground(AppTheme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.listBackground(for: colorScheme))
            .tint(AppTheme.Colors.primary)
            .navigationTitle(LocalizedStringKey("settings.title")) // i18n: settings.title
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

// MARK: - Helpers
private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
