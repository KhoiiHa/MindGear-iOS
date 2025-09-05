//
//  UIStyles.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 05.09.25.
//

import SwiftUI

// MARK: - Card Style (global)
struct MGCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.l, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

extension View {
    /// Einheitlicher Karten-Look für Listen- und Detail-Elemente.
    func mgCard() -> some View { modifier(MGCard()) }
}

// MARK: - Pill Button Style (global)
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.body.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(configuration.isPressed
                               ? AppTheme.Colors.accent.opacity(0.85)
                               : AppTheme.Colors.accent)
            )
            .foregroundStyle(Color.white)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}
