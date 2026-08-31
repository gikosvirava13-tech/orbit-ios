import TotemCore
import TotemUI
import SwiftUI

/// A chat list row.
///
/// Deliberately not the arrangement every messenger uses, which puts the time
/// at the top right and the badge at the bottom right and leaves the right
/// edge doing two unrelated jobs. Here the time sits with the name, because it
/// describes the same thing, and the right edge carries only the one piece of
/// state you scan for.
struct ChatRow: View {
    @Environment(AppSettings.self) private var settings

    let chat: Chat

    private var isUnread: Bool { chat.unreadCount > 0 }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(peer: chat.peer)

            VStack(alignment: .leading, spacing: 3) {
                titleLine
                previewLine
            }

            Spacer(minLength: 8)

            trailing
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var titleLine: some View {
        HStack(spacing: 5) {
            Text(chat.peer.name)
                // Unread names carry the weight, so the list can be read
                // without looking at the badges at all.
                .font(isUnread ? .headline : .body)
                .foregroundStyle(Theme.label)
                .lineLimit(1)

            if chat.peer.isVerified {
                VerifiedBadge()
            }

            if chat.isMuted {
                Image(systemName: "bell.slash.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
                    .accessibilityLabel("Muted")
            }

            Text(ChatDateFormatter.listStamp(for: chat.date))
                .font(.caption)
                .foregroundStyle(Theme.tertiaryLabel)
                // Never let a long name squeeze the timestamp out.
                .layoutPriority(1)
        }
    }

    private var previewLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            if chat.isTyping {
                HStack(spacing: 5) {
                    Text("typing")
                    TypingIndicator()
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            } else {
                if settings.readReceiptsEnabled,
                   let last = chat.lastMessage,
                   last.isOutgoing,
                   chat.unreadCount == 0 {
                    DeliveryTicks(delivery: last.delivery)
                        .foregroundStyle(Color.accentColor)
                }

                Text(chat.previewText)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryLabel)
                    // One line, not two. Shorter rows fit more conversations
                    // on screen, and the second line was almost always a
                    // fragment of a sentence nobody finished reading.
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isUnread {
            UnreadBadge(count: chat.unreadCount, isMuted: chat.isMuted)
        } else if chat.isPinned {
            Image(systemName: "pin.fill")
                .font(.caption2)
                .rotationEffect(.degrees(45))
                .foregroundStyle(Theme.tertiaryLabel)
                .accessibilityLabel("Pinned")
        }
    }
}

#Preview {
    List(PreviewData.chats) { chat in
        ChatRow(chat: chat)
    }
    .listStyle(.plain)
    .environment(AppSettings())
}
