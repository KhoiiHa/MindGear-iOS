import SwiftUI

/// Placeholder for the future onboarding flow.
struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("MindGear")
                .font(AppTheme.Fonts.title)
            Text("Dein Einstieg in mentale Stärke")
                .font(AppTheme.Fonts.body)
            // TODO: Add onboarding steps and visuals
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingView()
}
