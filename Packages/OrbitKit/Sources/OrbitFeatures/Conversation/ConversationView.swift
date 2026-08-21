import OrbitCore
import OrbitUI
import SwiftUI

public struct ConversationView: View {
    @Environment(ChatStore.self) private var store

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
                .padding(.vertical, 8)
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
        .safeAreaInset(edge: .bottom) {
            Composer { text in
                store.send(text: text, to: chatID)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                titleView(for: chat)
            }
        }
    }

    private var typingAnchor: String { "typing-indicator" }

    private func titleView(for chat: Chat) -> some View {
        HStack(spacing: 8) {
            AvatarView(peer: chat.peer, size: 30, showsPresence: false)

            VStack(spacing: 0) {
                Text(chat.peer.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(chat.statusText)
                    .font(.caption)
                    .foregroundStyle(chat.isTyping ? Color.accentColor : Theme.secondaryLabel)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Composer

struct Composer: View {
    let onSend: (String) -> Void

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Button {
                // Attachment picker lives here once media is supported.
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
            }
            .accessibilityLabel("Attach")

            TextField("Message", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1 ... 5)
                .focused($isFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background {
                    Capsule().stroke(Theme.separator, lineWidth: 1)
                }

            Button {
                guard canSend else { return }
                onSend(draft)
                draft = ""
            } label: {
                Image(systemName: canSend ? "arrow.up.circle.fill" : "mic")
                    .font(.title2)
            }
            .accessibilityLabel(canSend ? "Send" : "Record voice message")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // A plain bar material: on iOS 26 the system renders this as Liquid
        // Glass automatically, so there is nothing bespoke to maintain.
        .background(.bar)
    }
}

#Preview {
    NavigationStack {
        ConversationView(chatID: "c1")
            .environment(ChatStore())
            .environment(AppSettings())
    }
}
