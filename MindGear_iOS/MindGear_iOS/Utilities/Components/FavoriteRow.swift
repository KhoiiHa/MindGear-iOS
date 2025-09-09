import SwiftUI

/// Reusable row for Favorites lists (Videos, Mentors, Playlists).
/// UI‑only: pass already formatted strings/urls from the parent.
struct FavoriteRow: View {
    // MARK: Input
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var thumbnailURL: String? = nil
    var accessibilityIdentifier: String? = nil

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.m) {
            // Leading visual: thumbnail if available, else system image icon
            if let urlString = thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                            .fill(AppTheme.Colors.surfaceElevated)
                            .frame(width: 56, height: 56)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.s, style: .continuous))
                    case .failure:
                        fallbackIcon
                    @unknown default:
                        fallbackIcon
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.s, style: .continuous)
                        .stroke(AppTheme.Colors.cardStroke(for: scheme), lineWidth: 1)
                )
            } else {
                fallbackIcon
            }

            // Text stack
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary(for: scheme))
                    .lineLimit(2)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary(for: scheme))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary(for: scheme))
                .opacity(0.7)
        }
        .padding(.vertical, AppTheme.Spacing.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityIdentifier(accessibilityIdentifier ?? "favoriteRow")
    }

    private var fallbackIcon: some View {
        let symbol = systemImage ?? "star"
        return ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.s, style: .continuous)
                .fill(AppTheme.Colors.surfaceElevated)
                .frame(width: 56, height: 56)
            Image(systemName: symbol)
                .imageScale(.large)
                .foregroundStyle(AppTheme.textSecondary(for: scheme))
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.s, style: .continuous)
                .stroke(AppTheme.Colors.cardStroke(for: scheme), lineWidth: 1)
        )
    }

    private var accessibilityLabel: String {
        if let subtitle, !subtitle.isEmpty {
            return "\(title), \(subtitle)"
        } else {
            return title
        }
    }
}

#if DEBUG
struct FavoriteRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FavoriteRow(
                title: "Atomic Habits – How to build systems",
                subtitle: "James Clear • 12:34",
                systemImage: "play.rectangle.fill",
                thumbnailURL: "https://placehold.co/200x120",
                accessibilityIdentifier: "previewFavoriteRow"
            )
            .preferredColorScheme(.dark)
            .padding()
            .background(Color.black)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
