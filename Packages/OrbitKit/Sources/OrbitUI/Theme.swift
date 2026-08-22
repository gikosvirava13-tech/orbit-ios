import OrbitCore
import SwiftUI

/// Everything here resolves to a stock system colour. Nothing is a hand-picked
/// hex, so the app tracks light/dark, Increase Contrast and the user's tint
/// automatically — and there is no invented palette to disagree with.
public extension AccentPalette {
    /// Maps onto a system colour so the tint tracks appearance and contrast
    /// settings rather than being a fixed hex.
    var color: Color {
        switch self {
        case .blue: Color(.systemBlue)
        case .purple: Color(.systemPurple)
        case .pink: Color(.systemPink)
        case .orange: Color(.systemOrange)
        case .green: Color(.systemGreen)
        case .teal: Color(.systemTeal)
        }
    }
}

public enum Theme {
    // MARK: Surfaces

    public static let background = Color(.systemBackground)
    public static let groupedBackground = Color(.systemGroupedBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    public static let separator = Color(.separator)

    // MARK: Text

    public static let label = Color(.label)
    public static let secondaryLabel = Color(.secondaryLabel)
    public static let tertiaryLabel = Color(.tertiaryLabel)

    // MARK: Status

    public static let online = Color(.systemGreen)
    public static let away = Color(.systemOrange)
    public static let destructive = Color(.systemRed)

    // MARK: Bubbles

    /// Incoming bubbles use the system fill so they sit correctly on either
    /// appearance without a bespoke grey.
    public static let incomingBubble = Color(.secondarySystemFill)
    public static let incomingBubbleText = Color(.label)
    public static let outgoingBubble = Color.accentColor
    public static let outgoingBubbleText = Color.white

    // MARK: Avatars

    /// Telegram gives each peer one of a fixed set of two-stop gradients.
    /// These are built from system colours so they stay in family with the
    /// rest of the UI in both appearances.
    public static let avatarGradients: [[Color]] = [
        [Color(.systemBlue), Color(.systemIndigo)],
        [Color(.systemPink), Color(.systemRed)],
        [Color(.systemTeal), Color(.systemCyan)],
        [Color(.systemOrange), Color(.systemYellow)],
        [Color(.systemPurple), Color(.systemIndigo)],
        [Color(.systemGreen), Color(.systemTeal)],
        [Color(.systemBrown), Color(.systemOrange)]
    ]

    public static func avatarGradient(for index: Int) -> LinearGradient {
        // `abs` as well as the caller's masking — an out-of-range index here
        // would be an array crash, not a wrong colour.
        let colors = avatarGradients[abs(index) % avatarGradients.count]

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Metrics

public enum Metrics {
    public static let avatarSize: CGFloat = 56
    public static let smallAvatarSize: CGFloat = 36
    public static let bubbleCornerRadius: CGFloat = 18
    /// The squared-off corner that gives a bubble its tail.
    public static let bubbleTailRadius: CGFloat = 5
}

// MARK: - Motion

/// Standard iOS motion: no overshoot anywhere. Navigation and sheets already
/// animate themselves, so these are only for in-place content changes.
public enum Motion {
    public static let standard: Animation = .easeInOut(duration: 0.25)
    public static let quick: Animation = .easeOut(duration: 0.18)
}
