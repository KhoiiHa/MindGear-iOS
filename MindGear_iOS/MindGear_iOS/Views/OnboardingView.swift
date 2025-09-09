//
//  OnboardingView.swift
//  MindGear_iOS
//
//  Zweck: Einführungssequenz beim ersten Start (3 Seiten, Skip/Weiter, Abschluss-Flag).
//  Architekturrolle: SwiftUI View (präsentationsnah).
//  Verantwortung: Paging, Skip/Weiter-Steuerung, Onboarding-Flag via AppStorage.
//  Warum? Schlanke UI; Logik bleibt lokal, Rest der App bleibt entkoppelt.
//  Testbarkeit: Accessibility-IDs für Buttons/PageControl; Preview vorhanden.
//  Status: stabil.
//
import SwiftUI
import UIKit
// Kurzzusammenfassung: 3 Karten (Willkommen, Mentoren/Playlists, Performance) mit progressiver Navigation.
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var page: Int = 0
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                // Warum: Skip oben rechts – erwartet, leicht erreichbar, aber nicht dominant
                // Skip
                Button(NSLocalizedString("onboarding.skip", comment: "")) { finish() }
                    .accessibilityHint("Onboarding überspringen und zur App wechseln")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary(for: scheme))
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                    .accessibilityIdentifier("onboardingSkipButton")

                VStack(spacing: AppTheme.Spacing.l) {
                    TabView(selection: $page) {
                        OnboardingCard(
                            title: NSLocalizedString("onboarding.page1.title", comment: ""),
                            subtitle: NSLocalizedString("onboarding.page1.subtitle", comment: ""),
                            systemImage: "brain.head.profile"
                        )
                        .tag(0)
                        
                        OnboardingCard(
                            title: NSLocalizedString("onboarding.page2.title", comment: ""),
                            subtitle: NSLocalizedString("onboarding.page2.subtitle", comment: ""),
                            systemImage: "person.3.sequence.fill"
                        )
                        .tag(1)
                        
                        OnboardingCard(
                            title: NSLocalizedString("onboarding.page3.title", comment: ""),
                            subtitle: NSLocalizedString("onboarding.page3.subtitle", comment: ""),
                            systemImage: "bolt.fill"
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .frame(maxHeight: 520)
                    .accessibilityIdentifier("onboardingPageControl")

                    // Progress indicator (1/3)
                    Text("\(page + 1)/3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary(for: scheme))
                        .accessibilityLabel("Fortschritt \(page + 1) von 3")

                    // Primäraktion: Weiter/Start – füllt Breite, klare Call-to-Action
                    Button(action: advance) {
                        let label = page < 2 ? NSLocalizedString("onboarding.next", comment: "") : NSLocalizedString("onboarding.start", comment: "")
                        Text(page < 2 ? "\(label) (\(page + 1)/3)" : label)
                            .font(.headline)
                    }
                    .buttonStyle(PillButtonStyle())
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .accessibilityIdentifier(page < 2 ? "onboardingNextButton" : "onboardingStartButton")

                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.badge.fill")
                            Text(NSLocalizedString("onboarding.notifications.hint", comment: ""))
                        }
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary(for: scheme))
                    }
                    .padding(.bottom, AppTheme.Spacing.m)
                }
                .padding(.top, 48)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions
    /// Steuert das Paging und schließt das Onboarding.
    /// Warum: Einfache Logik lokal halten; AppState nur über `hasSeenOnboarding` berühren.
    private func advance() {
        if page < 2 {
            if reduceMotion {
                page += 1
            } else {
                withAnimation(.easeInOut) { page += 1 }
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            finish()
        }
    }

    /// Setzt das Onboarding-Flag und beendet die Sequenz.
    /// Warum: Single Source of Truth via AppStorage – andere Screens lesen dieses Flag.
    private func finish() { hasSeenOnboarding = true }
}

// MARK: - OnboardingCard (Subview)
private struct OnboardingCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Environment(\.colorScheme) private var scheme

    // MARK: - Body
    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
                    .accessibilityLabel(Text(title))
                    .accessibilityHidden(false)
            }
            .padding(.top, AppTheme.Spacing.l)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary(for: scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.m)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("onboardingCardTitle")

            Text(subtitle)
                .font(.body)
                .lineSpacing(3)
                .foregroundStyle(AppTheme.textSecondary(for: scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.m)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .mgCard()
        .padding(.horizontal, AppTheme.Spacing.m)
    }
}

// MARK: - Preview
#Preview { OnboardingView() }
#Preview("Seite 2") {
    OnboardingView()
}
