import OrbitCore
import SwiftUI

// MARK: - Wallpaper

/// The backdrop behind a conversation, and behind the Appearance preview.
///
/// Deliberately low contrast: a wallpaper that competes with the bubbles makes
/// text harder to read, and this one has to work under both appearances.
public struct WallpaperBackground: View {
    private let wallpaper: Wallpaper

    public init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
    }

    public var body: some View {
        ZStack {
            Theme.background

            if !wallpaper.colors.isEmpty {
                wallpaper.gradient.opacity(0.14)
            }
        }
    }
}

/// The same gradient at full strength, for a swatch in the picker.
public struct WallpaperSwatch: View {
    private let wallpaper: Wallpaper
    private let isSelected: Bool

    public init(wallpaper: Wallpaper, isSelected: Bool) {
        self.wallpaper = wallpaper
        self.isSelected = isSelected
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(wallpaper.colors.isEmpty ? AnyShapeStyle(Theme.secondaryBackground) : AnyShapeStyle(wallpaper.gradient))
            .frame(width: 54, height: 76)
            .overlay {
                if wallpaper.colors.isEmpty {
                    Image(systemName: "slash.circle")
                        .font(.title3)
                        .foregroundStyle(Theme.tertiaryLabel)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Theme.separator, lineWidth: isSelected ? 2.5 : 0.5)
            }
    }
}

// MARK: - Quick actions

/// The round glyph-over-caption control that sits under a profile header.
/// Apple uses this shape in Contacts; here it carries the profile shortcuts.
public struct QuickActionButton: View {
    private let symbol: String
    private let title: String
    private let action: () -> Void

    public init(symbol: String, title: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.14), in: Circle())

                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Usage bar

/// A proportional bar, used for the media cache breakdown.
///
/// Widths are computed against the width left over after the gaps, so the
/// segments always add up to the bar instead of overflowing it.
public struct UsageBar: View {
    public struct Segment: Identifiable, Sendable {
        public let id: String
        public let fraction: Double
        public let color: Color

        public init(id: String, fraction: Double, color: Color) {
            self.id = id
            self.fraction = fraction
            self.color = color
        }
    }

    private let segments: [Segment]
    private let height: CGFloat
    private let spacing: CGFloat = 2

    public init(segments: [Segment], height: CGFloat = 14) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            let gaps = CGFloat(max(segments.count - 1, 0)) * spacing
            let usable = max(geo.size.width - gaps, 0)

            HStack(spacing: spacing) {
                ForEach(segments) { segment in
                    Capsule(style: .continuous)
                        .fill(segment.color)
                        .frame(width: usable * segment.fraction)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// Colour swatch plus label, the legend under a `UsageBar`.
public struct UsageLegendRow: View {
    private let color: Color
    private let title: String
    private let detail: String

    public init(color: Color, title: String, detail: String) {
        self.color = color
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(title)

            Spacer(minLength: 8)

            Text(detail)
                .foregroundStyle(Theme.secondaryLabel)
                .monospacedDigit()
        }
    }
}

// MARK: - Cards

/// A rounded card sized to sit in a grouped list row whose insets have been
/// zeroed, so its edges line up with the section backgrounds above and below.
public struct SettingsCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background(
                Theme.secondaryBackground,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
    }
}

public extension View {
    /// Strips a grouped list row back to a bare canvas for a card.
    func plainCardRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

#Preview {
    List {
        Section {
            SettingsCard {
                VStack(spacing: 16) {
                    Text("Card").font(.headline)

                    HStack(spacing: 0) {
                        QuickActionButton(symbol: "square.and.pencil", title: "Edit") {}
                        QuickActionButton(symbol: "qrcode", title: "Code") {}
                        QuickActionButton(symbol: "square.and.arrow.up", title: "Share") {}
                    }
                }
                .padding(16)
            }
            .plainCardRow()
        }

        Section {
            UsageBar(segments: [
                .init(id: "a", fraction: 0.5, color: .blue),
                .init(id: "b", fraction: 0.3, color: .purple),
                .init(id: "c", fraction: 0.2, color: .teal)
            ])

            UsageLegendRow(color: .blue, title: "Photos", detail: "62 MB")
        }

        Section {
            HStack(spacing: 12) {
                ForEach(Wallpaper.allCases) { paper in
                    WallpaperSwatch(wallpaper: paper, isSelected: paper == .dusk)
                }
            }
        }
    }
}
