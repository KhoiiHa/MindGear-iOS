import SwiftUI

/// Placeholder for the future onboarding flow.
struct OnboardingView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Text("MindGear")
                .font(AppTheme.Typography.title)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text("Dein Einstieg in mentale Stärke")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: {
                // TODO: Handle onboarding continue
            }) {
                Text("Loslegen")
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.background)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .background(AppTheme.Colors.accent)
                    .cornerRadius(AppTheme.Radius.m)
            }
            .padding(.top, AppTheme.Spacing.l)
            // TODO: Add onboarding steps and visuals
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingView()
}
