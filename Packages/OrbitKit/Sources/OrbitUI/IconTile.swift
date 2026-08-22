import SwiftUI

/// The tinted rounded-square glyph that leads a row in iOS Settings.
///
/// Sized to match `Label`'s default icon column so rows line up whether or not
/// they have one, and drawn as a `Label` icon rather than an ad-hoc `HStack`
/// so Dynamic Type still moves the text independently.
public struct IconTile: View {
    private let symbol: String
    private let tint: Color
    private let side: CGFloat

    public init(symbol: String, tint: Color, side: CGFloat = 29) {
        self.symbol = symbol
        self.tint = tint
        self.side = side
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
            .fill(tint)
            .frame(width: side, height: side)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: side * 0.52, weight: .medium))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    List {
        Label {
            Text("Notifications and Sounds")
        } icon: {
            IconTile(symbol: "bell.badge.fill", tint: Color(.systemRed))
        }

        Label {
            Text("Privacy and Security")
        } icon: {
            IconTile(symbol: "lock.fill", tint: Color(.systemGray))
        }

        Label {
            Text("Appearance")
        } icon: {
            IconTile(symbol: "circle.lefthalf.filled", tint: Color(.systemBlue))
        }
    }
}
