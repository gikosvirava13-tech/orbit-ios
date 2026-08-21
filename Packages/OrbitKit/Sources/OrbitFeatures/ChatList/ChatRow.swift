import OrbitCore
import OrbitUI
import SwiftUI

struct ChatRow: View {
    @Environment(AppSettings.self) private var settings

    let chat: Chat

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(peer: chat.peer)

            VStack(alignment: .leading, spacing: 2) {
                titleLine
                previewLine
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var titleLine: some View {
        HStack(spacing: 4) {
            Text(chat.peer.name)
                .font(.headline)
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

            Spacer(minLength: 8)

            Text(ChatDateFormatter.listStamp(for: chat.date))
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryLabel)
        }
    }

    private var previewLine: some View {
        HStack(alignment: .top, spacing: 8) {
            if chat.isTyping {
                HStack(spacing: 5) {
                    Text("typing")
                    TypingIndicator()
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
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
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 4)

            if chat.unreadCount > 0 {
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
}

#Preview {
    List(PreviewData.chats) { chat in
        ChatRow(chat: chat)
    }
    .listStyle(.plain)
    .environment(AppSettings())
}
