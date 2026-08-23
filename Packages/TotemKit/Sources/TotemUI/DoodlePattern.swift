import SwiftUI

/// The line-art scatter behind a conversation.
///
/// Drawn from SF Symbols on a staggered grid rather than shipped as an image:
/// it costs nothing in the bundle, it takes the wallpaper's own colour so it
/// works on either appearance, and it scales to any screen without a set of
/// @2x/@3x assets.
///
/// The scatter is a hash of the cell coordinates, not `random()` — a pattern
/// that reshuffled on every redraw would shimmer while you scroll.
public struct DoodlePattern: View {
    private let tint: Color
    private let cell: CGFloat

    public init(tint: Color, cell: CGFloat = 78) {
        self.tint = tint
        self.cell = cell
    }

    public var body: some View {
        GeometryReader { geo in
            let columns = Int(ceil(geo.size.width / cell)) + 1
            let rows = Int(ceil(geo.size.height / cell)) + 1

            ForEach(0 ..< rows, id: \.self) { row in
                ForEach(0 ..< columns, id: \.self) { column in
                    glyph(row: row, column: column)
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private func glyph(row: Int, column: Int) -> some View {
        let seed = Self.hash(row, column)
        let symbol = Self.symbols[seed % Self.symbols.count]
        let size = 17 + CGFloat(seed / 7 % 9)
        let angle = Double(seed / 13 % 44) - 22
        let jitterX = CGFloat(seed / 3 % 22) - 11
        let jitterY = CGFloat(seed / 5 % 22) - 11

        // Every other row is offset half a cell, so the grid reads as a
        // scatter instead of as columns.
        let stagger = row.isMultiple(of: 2) ? 0 : cell / 2

        return Image(systemName: symbol)
            .font(.system(size: size, weight: .light))
            .foregroundStyle(tint)
            .rotationEffect(.degrees(angle))
            .position(
                x: CGFloat(column) * cell + stagger + jitterX,
                y: CGFloat(row) * cell + jitterY
            )
    }

    /// Masked to 31 bits so the index can never come out negative.
    private static func hash(_ a: Int, _ b: Int) -> Int {
        ((a &+ 1) &* 73_856_093 ^ (b &+ 1) &* 19_349_663) & 0x7FFF_FFFF
    }

    private static let symbols = [
        "leaf.fill",
        "pawprint.fill",
        "fish.fill",
        "bird.fill",
        "ant.fill",
        "tortoise.fill",
        "hare.fill",
        "carrot.fill",
        "ladybug.fill",
        "lizard.fill",
        "teddybear.fill",
        "camera.macro",
        "drop.fill",
        "moon.fill",
        "sparkle",
        "cloud.fill"
    ]
}

#Preview {
    ZStack {
        Color.black
        DoodlePattern(tint: Theme.aurora.opacity(0.5))
    }
    .ignoresSafeArea()
}
