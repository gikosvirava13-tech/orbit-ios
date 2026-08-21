import OrbitCore
import SwiftUI

/// Unread pill on a chat row. Muted chats get the grey variant, as in Telegram.
public struct UnreadBadge: View {
    private let count: Int
    private let isMuted: Bool

    public init(count: Int, isMuted: Bool) {
        self.count = count
        self.isMuted = isMuted
    }

    public var body: some View {
        Text(count > 999 ? "999+" : count.formatted())
            .font(.footnote.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(minWidth: 22, minHeight: 22)
            .background(isMuted ? AnyShapeStyle(Color(.systemGray)) : AnyShapeStyle(Color.accentColor))
            .clipShape(Capsule())
            .accessibilityLabel("\(count) unread")
    }
}

/// The blue check next to a verified channel name.
public struct VerifiedBadge: View {
    public init() {}

    public var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.footnote)
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel("Verified")
    }
}

/// Delivery state: a clock while sending, one tick for sent, two for read.
///
/// Deliberately not `checkmark.circle.fill` — filled in the tint colour it is
/// almost indistinguishable from `checkmark.seal.fill` on a verified peer, and
/// the two appear within a couple of rows of each other in the chat list.
public struct DeliveryTicks: View {
    private let delivery: Message.Delivery

    public init(delivery: Message.Delivery) {
        self.delivery = delivery
    }

    public var body: some View {
        content
            .font(.caption2.weight(.semibold))
            .accessibilityLabel(label)
    }

    @ViewBuilder
    private var content: some View {
        switch delivery {
        case .sending:
            Image(systemName: "clock")
        case .sent:
            Image(systemName: "checkmark")
        case .read:
            // SF Symbols has no double checkmark, so two are overlapped.
            HStack(spacing: -3.5) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
        }
    }

    private var label: String {
        switch delivery {
        case .sending: "Sending"
        case .sent: "Sent"
        case .read: "Read"
        }
    }
}

/// Three-dot typing indicator. Slow, low-contrast, no bounce.
public struct TypingIndicator: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0 ..< 3, id: \.self) { index in
                Circle()
                    .frame(width: 4, height: 4)
                    .opacity(phase == index ? 1 : 0.35)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(Motion.quick) { phase = (phase + 1) % 3 }
        }
        .accessibilityLabel("Typing")
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            UnreadBadge(count: 3, isMuted: false)
            UnreadBadge(count: 128, isMuted: true)
            VerifiedBadge()
        }
        HStack(spacing: 12) {
            DeliveryTicks(delivery: .sending)
            DeliveryTicks(delivery: .sent)
            DeliveryTicks(delivery: .read)
        }
        TypingIndicator()
    }
    .padding()
}
