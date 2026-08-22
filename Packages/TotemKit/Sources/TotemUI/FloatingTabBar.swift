import SwiftUI

/// Floating glass tab bar: a capsule of items with a selection blob, and a
/// detached circular action button beside it.
///
/// The blob is finger-attached. One `DragGesture(minimumDistance: 0)` serves
/// both tapping and dragging — press anywhere and the blob comes to you, slide
/// across and it tracks continuously, selecting each tab as you pass it, then
/// settles on release. Two gestures would fight for the same touch.
///
/// It is a glass element in its own right, not a flat fill: sitting inside the
/// same `GlassEffectContainer` as the bar, the system blends the two, which is
/// what makes it read as a droplet in the bar rather than a rectangle drawn on
/// top of it. Under the finger it swells past the bar's edges and stretches
/// along the direction of travel, so the motion has weight.
public struct FloatingTabBar<Tab: Hashable>: View {
    public struct Item: Identifiable {
        public let id: Tab
        public let title: String
        public let systemImage: String
        public let badge: Int

        public init(id: Tab, title: String, systemImage: String, badge: Int = 0) {
            self.id = id
            self.title = title
            self.systemImage = systemImage
            self.badge = badge
        }
    }

    @Binding private var selection: Tab
    private let items: [Item]
    private let trailingAction: (() -> Void)?
    private let trailingSymbol: String

    /// Finger position while dragging; `nil` means the blob rests on the
    /// selected item.
    @State private var dragX: CGFloat?

    /// Swollen while a finger is down.
    @State private var isHeld = false

    /// Squash and stretch, driven by drag velocity. `1 × 1` is at rest.
    @State private var jelly = CGSize(width: 1, height: 1)

    private let height: CGFloat = 58

    public init(
        selection: Binding<Tab>,
        items: [Item],
        trailingSymbol: String = "magnifyingglass",
        trailingAction: (() -> Void)? = nil
    ) {
        _selection = selection
        self.items = items
        self.trailingSymbol = trailingSymbol
        self.trailingAction = trailingAction
    }

    public var body: some View {
        HStack(spacing: 10) {
            capsuleBar

            if let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingSymbol)
                }
                .buttonStyle(GlassCircleButtonStyle(diameter: height))
            }
        }
        // Groups the bar, the blob and the search button into one glass scope
        // so the system can blend them where they meet.
        .liquidGlassGroup(spacing: 18)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private var capsuleBar: some View {
        GeometryReader { geo in
            let slot = geo.size.width / CGFloat(max(items.count, 1))
            let restingX = slot * (CGFloat(selectedIndex) + 0.5)
            let bubbleX = dragX.map { $0.clamped(to: slot / 2 ... geo.size.width - slot / 2) }
                ?? restingX

            ZStack(alignment: .leading) {
                blob(slot: slot)
                    .position(x: bubbleX, y: height / 2)

                HStack(spacing: 0) {
                    ForEach(items) { item in
                        itemLabel(item)
                            .frame(width: slot, height: height)
                    }
                }
            }
            .contentShape(.rect)
            .gesture(dragGesture(slot: slot))
        }
        .frame(height: height)
        .liquidGlass(in: .capsule)
        // The bar is one gesture surface, not four buttons, so UI tests
        // address it by normalized coordinate rather than by item.
        //
        // `.contain` is what actually publishes it: an identifier alone lands
        // on a view that is not itself an accessibility element, so nothing
        // ends up in the hierarchy to query. This keeps the children visible
        // and adds a container around them.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tabBar")
    }

    // MARK: Blob

    /// Swells past the bar's height while held, so it bulges out of the
    /// capsule the way a droplet would rather than staying boxed inside it.
    private func blob(slot: CGFloat) -> some View {
        let width = min(slot - (isHeld ? 2 : 10), isHeld ? 78 : 68)
        let blobHeight = isHeld ? height + 6 : height - 8

        return Capsule(style: .continuous)
            // A tint over the glass, so the blob stays legible on top of the
            // bar's own glass — two identical materials would cancel out.
            .fill(Color.accentColor.opacity(0.18))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.75)
            }
            .frame(width: max(width, 44), height: blobHeight)
            .liquidGlass(in: Capsule(style: .continuous), interactive: true)
            .scaleEffect(x: jelly.width, y: jelly.height)
            .animation(.spring(response: 0.30, dampingFraction: 0.68), value: isHeld)
            .animation(.interactiveSpring(response: 0.16, dampingFraction: 0.70), value: jelly)
    }

    private func itemLabel(_ item: Item) -> some View {
        let isSelected = item.id == selection

        return VStack(spacing: 3) {
            Image(systemName: item.systemImage)
                .font(.system(size: 21, weight: .regular))
                .overlay(alignment: .topTrailing) {
                    if item.badge > 0 {
                        Text(item.badge > 999 ? "999+" : item.badge.formatted())
                            .font(.system(size: 11, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Theme.coral, in: Capsule())
                            .alignmentGuide(.top) { $0[.bottom] - 8 }
                            .alignmentGuide(.trailing) { $0[.leading] + 10 }
                    }
                }

            Text(item.title)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.secondary))
        .animation(.easeInOut(duration: 0.2), value: selection)
        // Combined into one element per tab so a test can address a single
        // item. Hit testing is unaffected — a tap still lands on the shared
        // drag gesture underneath.
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tab-\(item.title)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var selectedIndex: Int {
        items.firstIndex { $0.id == selection } ?? 0
    }

    private func dragGesture(slot: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // First touch animates the blob over and swells it; subsequent
                // movement tracks the finger directly so it never lags behind.
                if dragX == nil {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                        dragX = value.location.x
                        isHeld = true
                    }
                } else {
                    dragX = value.location.x
                }

                jelly = Self.jelly(forSpeed: value.velocity.width)

                let index = Int(value.location.x / slot).clamped(to: 0 ... items.count - 1)
                if items[index].id != selection {
                    selection = items[index].id
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.62)) {
                    dragX = nil
                    isHeld = false
                    jelly = CGSize(width: 1, height: 1)
                }
            }
    }

    /// Stretch along the direction of travel, squash across it — the pair of
    /// deformations that reads as a liquid rather than a scaling rectangle.
    /// Capped well short of a caricature: the point is weight, not bounce.
    private static func jelly(forSpeed speed: CGFloat) -> CGSize {
        let normalized = min(abs(speed), 2_400) / 2_400
        let amount = normalized * 0.24

        return CGSize(width: 1 + amount, height: 1 - amount * 0.55)
    }
}

// MARK: - Helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    struct Harness: View {
        @State private var tab = 0

        var body: some View {
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [Theme.iris, Theme.orchid, Theme.coral],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                FloatingTabBar(
                    selection: $tab,
                    items: [
                        .init(id: 0, title: "Contacts", systemImage: "person.crop.circle.fill", badge: 1),
                        .init(id: 1, title: "Calls", systemImage: "phone.fill"),
                        .init(id: 2, title: "Chats", systemImage: "bubble.left.and.bubble.right.fill", badge: 833),
                        .init(id: 3, title: "Settings", systemImage: "gearshape.fill")
                    ],
                    trailingAction: {}
                )
            }
        }
    }

    return Harness()
}
