import SwiftUI

/// Floating glass tab bar: a capsule of items with a selection bubble, and a
/// detached circular action button beside it.
///
/// The bubble is finger-attached. One `DragGesture(minimumDistance: 0)` serves
/// both tapping and dragging — press anywhere and the bubble comes to you,
/// slide across and it tracks continuously, selecting each tab as you pass it,
/// then settles on release. Two gestures would fight for the same touch.
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

    /// Finger position while dragging; `nil` means the bubble rests on the
    /// selected item.
    @State private var dragX: CGFloat?

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
        .liquidGlassGroup()
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
                Capsule()
                    .fill(Color.primary.opacity(0.10))
                    .frame(width: slot - 6, height: height - 10)
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
                            .background(Color(.systemRed), in: Capsule())
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
                // First touch animates the bubble over; subsequent movement
                // tracks the finger directly so it never lags behind.
                if dragX == nil {
                    withAnimation(.snappy(duration: 0.22, extraBounce: 0)) {
                        dragX = value.location.x
                    }
                } else {
                    dragX = value.location.x
                }

                let index = Int(value.location.x / slot).clamped(to: 0 ... items.count - 1)
                if items[index].id != selection {
                    selection = items[index].id
                }
            }
            .onEnded { _ in
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    dragX = nil
                }
            }
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
                LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                FloatingTabBar(
                    selection: $tab,
                    items: [
                        .init(id: 0, title: "Chats", systemImage: "bubble.left.and.bubble.right.fill", badge: 528),
                        .init(id: 1, title: "Contacts", systemImage: "person.crop.circle"),
                        .init(id: 2, title: "Settings", systemImage: "gearshape.fill")
                    ],
                    trailingAction: {}
                )
            }
        }
    }

    return Harness()
}
