import OrbitCore
import OrbitUI
import SwiftUI

struct MessageBubble: View {
    @Environment(AppSettings.self) private var settings

    let message: Message
    let showsAuthor: Bool

    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 48) }

            VStack(alignment: .leading, spacing: 2) {
                if showsAuthor, let author = message.authorName, !message.isOutgoing {
                    Text(author)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                Text(message.text)
                    .font(.body)

                metaLine
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(message.isOutgoing ? Theme.outgoingBubbleText : Theme.incomingBubbleText)
            .background(message.isOutgoing ? AnyShapeStyle(Theme.outgoingBubble) : AnyShapeStyle(Theme.incomingBubble))
            .clipShape(bubbleShape)
            .overlay(alignment: message.isOutgoing ? .bottomTrailing : .bottomLeading) {
                if let reaction = message.reaction {
                    Text(reaction)
                        .font(.footnote)
                        .padding(5)
                        .background(Theme.background, in: Circle())
                        .overlay(Circle().stroke(Theme.separator, lineWidth: 0.5))
                        .offset(x: message.isOutgoing ? -10 : 10, y: 12)
                }
            }
            .padding(.bottom, message.reaction == nil ? 0 : 14)

            if !message.isOutgoing { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
    }

    /// One squared-off corner on the sending side gives the bubble its tail
    /// without a custom path.
    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Metrics.bubbleCornerRadius,
            bottomLeadingRadius: message.isOutgoing ? Metrics.bubbleCornerRadius : Metrics.bubbleTailRadius,
            bottomTrailingRadius: message.isOutgoing ? Metrics.bubbleTailRadius : Metrics.bubbleCornerRadius,
            topTrailingRadius: Metrics.bubbleCornerRadius,
            style: .continuous
        )
    }

    private var metaLine: some View {
        HStack(spacing: 3) {
            Text(ChatDateFormatter.bubbleStamp(for: message.date))
                .monospacedDigit()

            if message.isOutgoing, settings.readReceiptsEnabled {
                DeliveryTicks(delivery: message.delivery)
            }
        }
        .font(.caption2)
        .foregroundStyle(message.isOutgoing ? Theme.outgoingBubbleText.opacity(0.75) : Theme.secondaryLabel)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// Centred day header between message groups.
struct DaySeparator: View {
    let date: Date

    var body: some View {
        Text(ChatDateFormatter.daySeparator(for: date))
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.secondaryLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 3) {
            DaySeparator(date: .now)
            ForEach(PreviewData.chats[0].messages) { message in
                MessageBubble(message: message, showsAuthor: false)
            }
        }
        .padding(.horizontal, 12)
    }
    .environment(AppSettings())
}
