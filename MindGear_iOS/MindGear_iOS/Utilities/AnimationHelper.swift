import SwiftUI

/// Helper providing default animations for later use.
enum AnimationHelper {
    /// Standard fade transition used across the app.
    static let fade: Animation = .easeInOut(duration: 0.3)

    /// Placeholder for additional animations.
    static let quickBounce: Animation = .spring(response: 0.25, dampingFraction: 0.7)
}
