import TotemCore
import TotemUI
import SwiftUI

/// A conversation, with the chrome floating over the wallpaper rather than
/// sitting in bars above and below it.
///
/// The system navigation bar is hidden and replaced with three separate glass
/// pieces — a back pill carrying the unread count, the title, and the avatar —
/// so the wallpaper runs edge to edge and messages scroll underneath them. The
/// composer is built the same way: an attach button, the field, and send, each
/// its own floating shape with the wallpaper showing through between them.
public struct ConversationView: View {
    @Environment(ChatStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    private let chatID: String

    public init(chatID: String) {
        self.chatID = chatID
    }

    public var body: some View {
        Group {
            if let chat = store.chat(id: chatID) {
                content(for: chat)
            } else {
                ContentUnavailableView(
                    "Conversation Unavailable",
                    systemImage: "bubble.left.and.bubble.right"
                )
            }
        }
    }

    @ViewBuilder
    private func content(for chat: Chat) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 3) {
                    ForEach(ChatDateFormatter.groupByDay(chat.messages)) { group in
                        Section {
                            ForEach(group.messages) { message in
                                MessageBubble(message: message, showsAuthor: chat.peer.kind != .user)
                                    .id(message.id)
                            }
                        } header: {
                            DaySeparator(date: group.date)
                        }
                    }

                    if chat.isTyping {
                        HStack {
                            TypingIndicator()
                                .foregroundStyle(Theme.secondaryLabel)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Theme.incomingBubble, in: Capsule())
                            Spacer(minLength: 48)
                        }
                        .id(typingAnchor)
                    }
                }
                .padding(.horizontal, 12)
                // Clears the floating header, which the content scrolls under.
                .padding(.top, 64)
                .padding(.bottom, 8)
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: chat.messages.count) {
                guard let last = chat.messages.last else { return }
                withAnimation(Motion.standard) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        // Only the bubbles take the Text Size setting. The chrome around them
        // keeps following the system, the way Messages behaves.
        .dynamicTypeSize(settings.textSize.dynamicTypeSize)
        .safeAreaInset(edge: .bottom) {
            Composer { text in
                store.send(text: text, to: chatID)
            }
        }
        .overlay(alignment: .top) {
            header(for: chat)
        }
        .background {
            WallpaperBackground(wallpaper: settings.wallpaper)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var typingAnchor: String { "typing-indicator" }

    // MARK: Header

    private func header(for chat: Chat) -> some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))

                    if unreadElsewhere > 0 {
                        Text(unreadElsewhere.formatted())
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, unreadElsewhere > 0 ? 14 : 16)
                .frame(height: 44)
            }
            .buttonStyle(.plain)
            .liquidGlass(in: .capsule, interactive: true)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("back")

            VStack(spacing: 0) {
                Text(chat.peer.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(chat.statusText)
                    .font(.caption)
                    .foregroundStyle(chat.isTyping ? Color.accentColor : Theme.secondaryLabel)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .liquidGlass(in: .capsule)
            .accessibilityElement(children: .combine)

            AvatarView(peer: chat.peer, size: 44, showsPresence: false)
        }
        .liquidGlassGroup(spacing: 10)
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    /// What is waiting in every other conversation — the number you are going
    /// back to, which is why it belongs on the back button.
    private var unreadElsewhere: Int {
        store.chats
            .filter { $0.id != chatID }
            .reduce(0) { $0 + $1.unreadCount }
    }
}

// MARK: - Composer

struct Composer: View {
    let onSend: (String) -> Void

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    private let control: CGFloat = 46

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Button {
                // Attachment picker lives here once media is supported.
            } label: {
                Image(systemName: "paperclip")
            }
            .buttonStyle(GlassCircleButtonStyle(diameter: control))
            .accessibilityLabel("Attach")

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1 ... 5)
                    .focused($isFocused)
                    .accessibilityIdentifier("composer")

                Button {
                    // A sticker and emoji picker lives here.
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.secondaryLabel)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stickers")
                .padding(.bottom, 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: control)
            .liquidGlass(in: .capsule)

            Button {
                guard canSend else { return }
                onSend(draft)
                draft = ""
            } label: {
                // The glyph swaps in place rather than the button changing
                // shape, so the row never reflows as you type.
                Image(systemName: canSend ? "arrow.up" : "mic.fill")
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(GlassCircleButtonStyle(diameter: control))
            .accessibilityLabel(canSend ? "Send" : "Record voice message")
            .accessibilityIdentifier("send")
        }
        .liquidGlassGroup(spacing: 10)
        .animation(Motion.quick, value: canSend)
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}

#Preview {
    NavigationStack {
        ConversationView(chatID: "c1")
            .environment(ChatStore())
            .environment(AppSettings())
    }
}
