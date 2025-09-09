//
//  SectionHeader.swift
//  MindGear_iOS
//
//  Created by Vu Minh Khoi Ha on 09.09.25.
//

import SwiftUI

/// Einheitlicher Abschnitts-Header für Listen/Grids.
/// Unterstützt Titel, optionalen Untertitel und optionalen Trailing-Action („Alle anzeigen“).
struct SectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var showAction: Bool = false
    var actionTitle: LocalizedStringKey = "section.seeAll"
    var action: (() -> Void)? = nil

    @Environment(\.colorScheme) private var scheme
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: scheme))
                }
            }
            Spacer()
            if showAction, let action {
                Button(actionTitle) { action() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .buttonStyle(.plain)
                    .accessibilityLabel(actionTitle)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, AppTheme.Spacing.m)
        .padding(.bottom, AppTheme.Spacing.s)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
struct SectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SectionHeader(title: "section.recommended")
                .environment(\.locale, .init(identifier: "de"))
                .preferredColorScheme(.dark)

            SectionHeader(title: "section.yourMentors", subtitle: "Optional subtitle", showAction: true) {}
                .environment(\.locale, .init(identifier: "en"))
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black)
    }
}
#endif
