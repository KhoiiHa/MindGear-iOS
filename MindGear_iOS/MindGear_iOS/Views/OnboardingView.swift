import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var page: Int = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                // Skip
                Button("Überspringen") { finish() }
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                    .accessibilityIdentifier("onboardingSkipButton")

                VStack(spacing: AppTheme.Spacing.l) {
                    TabView(selection: $page) {
                        OnboardingCard(
                            title: "Willkommen bei MindGear",
                            subtitle: "Entdecke kuratierte Inhalte zu Mindset, Fokus und mentaler Stärke.",
                            systemImage: "brain.head.profile"
                        )
                        .tag(0)

                        OnboardingCard(
                            title: "Mentoren & Playlists",
                            subtitle: "Folge Mentoren, speichere Playlists als Favoriten und finde schnell, was dich weiterbringt.",
                            systemImage: "person.3.sequence.fill"
                        )
                        .tag(1)

                        OnboardingCard(
                            title: "Schnell & Offline‑freundlich",
                            subtitle: "Cleveres Caching, Verlauf & Favoriten – für eine flüssige Experience.",
                            systemImage: "bolt.fill"
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .frame(maxHeight: 520)

                    Button(action: advance) {
                        Text(page < 2 ? "Weiter" : "Los geht’s")
                            .font(AppTheme.Typography.subtitle)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.Colors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .accessibilityIdentifier(page < 2 ? "onboardingNextButton" : "onboardingStartButton")

                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.badge.fill")
                            Text("Benachrichtigungen später in den Einstellungen aktivieren.")
                        }
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(.bottom, AppTheme.Spacing.m)
                }
                .padding(.top, 48)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func advance() {
        if page < 2 {
            withAnimation(.easeInOut) { page += 1 }
        } else { finish() }
    }

    private func finish() { hasSeenOnboarding = true }
}

private struct OnboardingCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.primary.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(.top, AppTheme.Spacing.l)

            Text(title)
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.m)

            Text(subtitle)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.m)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.Colors.surface)
        )
        .padding(.horizontal, AppTheme.Spacing.m)
    }
}

#Preview { OnboardingView() }
