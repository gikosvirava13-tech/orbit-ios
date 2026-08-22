import TotemCore
import SwiftUI
import UIKit

// MARK: - Colour construction

public extension Color {
    /// A hand-mixed colour with a twin for dark mode.
    ///
    /// Two hexes rather than one colour dimmed by opacity: a mid-tone that
    /// reads well on white goes muddy on black, and an opacity tweak cannot
    /// fix hue. The pair is resolved by the trait collection, so everything
    /// still follows the system appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Palette

/// Totem's own colourway. Not Apple's system colours: those are shared with
/// every other app on the phone, and an app with no identity of its own reads
/// as a settings screen. Structure still comes from the system — greys, fills
/// and separators are all semantic — so only the hues are ours.
public extension Theme {
    static let aurora = Color(light: 0x0E9F5F, dark: 0x28C07C)
    static let cobalt = Color(light: 0x2A5BD7, dark: 0x5B8CF7)
    static let iris = Color(light: 0x4B4FCF, dark: 0x7B7FF0)
    static let orchid = Color(light: 0x7A45D6, dark: 0x9E70F5)
    static let coral = Color(light: 0xD93C5C, dark: 0xF2647F)
    static let amber = Color(light: 0xB5730A, dark: 0xE0992B)
    static let lagoon = Color(light: 0x0E8C9E, dark: 0x2BB8CC)
    static let slate = Color(light: 0x6B7280, dark: 0x8A919C)
}

public extension AccentPalette {
    var color: Color {
        switch self {
        case .aurora: Theme.aurora
        case .cobalt: Theme.cobalt
        case .orchid: Theme.orchid
        case .coral: Theme.coral
        case .amber: Theme.amber
        case .lagoon: Theme.lagoon
        }
    }
}

public enum Theme {
    // MARK: Surfaces

    public static let background = Color(.systemBackground)
    public static let groupedBackground = Color(.systemGroupedBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    public static let separator = Color(.separator)

    /// A raised patch on top of a card — the quick-action buttons sit on it.
    /// A translucent fill rather than a fixed grey, so it lifts off whatever
    /// it happens to be laid over.
    public static let tile = Color(.secondarySystemFill)

    // MARK: Text

    public static let label = Color(.label)
    public static let secondaryLabel = Color(.secondaryLabel)
    public static let tertiaryLabel = Color(.tertiaryLabel)

    // MARK: Status

    public static let online = aurora
    public static let away = amber
    /// Stays the system red: SwiftUI paints `role: .destructive` in its own
    /// red whatever we do, and a second, nearly-red red beside it looks like
    /// a mistake rather than a decision.
    public static let destructive = Color(.systemRed)

    // MARK: Bubbles

    /// Incoming bubbles use the system fill so they sit correctly on either
    /// appearance, and over a wallpaper, without a bespoke grey.
    public static let incomingBubble = Color(.secondarySystemFill)
    public static let incomingBubbleText = Color(.label)
    public static let outgoingBubble = Color.accentColor
    public static let outgoingBubbleText = Color.white

    // MARK: Avatars

    /// Each peer gets one of a fixed set of two-stop gradients, mixed from the
    /// palette above so avatars belong to the same colourway as everything
    /// else instead of being a second, unrelated set of hues.
    public static let avatarGradients: [[Color]] = [
        [cobalt, orchid],
        [coral, amber],
        [lagoon, aurora],
        [amber, coral],
        [orchid, iris],
        [aurora, lagoon],
        [iris, cobalt]
    ]

    public static func avatarGradient(for index: Int) -> LinearGradient {
        // `abs` as well as the caller's masking — an out-of-range index here
        // would be an array crash, not a wrong colour.
        let colors = avatarGradients[abs(index) % avatarGradients.count]

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: Storage

    /// Colours for the storage bar, in the order the categories are listed.
    public static let usageColors: [Color] = [cobalt, orchid, lagoon, amber, slate]

    public static func usageColor(_ index: Int) -> Color {
        usageColors[abs(index) % usageColors.count]
    }
}

// MARK: - Wallpaper

public extension Wallpaper {
    /// Two palette colours per wallpaper, drawn at low opacity behind a
    /// conversation so bubbles stay the brightest thing on screen.
    var colors: [Color] {
        switch self {
        case .plain: []
        case .dusk: [Theme.iris, Theme.orchid]
        case .mint: [Theme.aurora, Theme.lagoon]
        case .ember: [Theme.amber, Theme.coral]
        case .graphite: [Theme.slate, Color(light: 0xB6BAC1, dark: 0x3C4148)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: colors.isEmpty ? [.clear, .clear] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Text size

public extension TextSize {
    /// Maps onto Dynamic Type rather than a font-size multiplier, so the
    /// system handles line height and layout the way it does everywhere else.
    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: .small
        case .standard: .medium
        case .large: .large
        case .extraLarge: .xLarge
        }
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
