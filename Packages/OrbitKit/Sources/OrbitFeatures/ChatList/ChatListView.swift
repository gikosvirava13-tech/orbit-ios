import OrbitCore
import OrbitUI
import SwiftUI

public struct ChatListView: View {
    @Environment(ChatStore.self) private var store

    @State private var search = ""
    @State private var scope: ChatListFilter = .all
    @State private var path: [String] = []
    @State private var isComposing = false

    public init() {}

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(visibleChats) { chat in
                    Button {
                        store.markRead(chatID: chat.id)
                        path.append(chat.id)
                    } label: {
                        ChatRow(chat: chat)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(.init(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .swipeActions(edge: .trailing) {
                        Button {
                            store.toggleMuted(chatID: chat.id)
                        } label: {
                            Label(
                                chat.isMuted ? "Unmute" : "Mute",
                                systemImage: chat.isMuted ? "bell" : "bell.slash"
                            )
                        }
                        .tint(Color.accentColor)

                        Button {
                            store.togglePinned(chatID: chat.id)
                        } label: {
                            Label(
                                chat.isPinned ? "Unpin" : "Pin",
                                systemImage: chat.isPinned ? "pin.slash" : "pin"
                            )
                        }
                        .tint(Color(.systemOrange))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .searchable(text: $search, prompt: "Search chats and messages")
            // Apple's own scope bar — the segmented control appears under the
            // search field while searching, so folders cost no permanent chrome.
            .searchScopes($scope) {
                ForEach(ChatListFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .overlay {
                if visibleChats.isEmpty {
                    emptyState
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposing = true
                    } label: {
                        Label("New chat", systemImage: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(for: String.self) { chatID in
                ConversationView(chatID: chatID)
            }
            .sheet(isPresented: $isComposing) {
                NewChatSheet { chatID in
                    isComposing = false
                    store.markRead(chatID: chatID)
                    path.append(chatID)
                }
            }
        }
    }

    private var visibleChats: [Chat] {
        store.sorted(filter: search.isEmpty ? .all : scope, search: search)
    }

    @ViewBuilder
    private var emptyState: some View {
        if search.isEmpty {
            ContentUnavailableView(
                "No Chats",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Start a conversation to see it here.")
            )
        } else {
            ContentUnavailableView.search(text: search)
        }
    }
}

/// Contact picker behind the compose button.
struct NewChatSheet: View {
    @Environment(ChatStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List(store.chats.filter { $0.peer.kind == .user }) { chat in
                Button {
                    onSelect(chat.id)
                } label: {
                    HStack(spacing: 12) {
                        AvatarView(peer: chat.peer, size: Metrics.smallAvatarSize + 8)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(chat.peer.name)
                                .font(.body)
                                .foregroundStyle(Theme.label)
                            Text(chat.statusText)
                                .font(.footnote)
                                .foregroundStyle(Theme.secondaryLabel)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ChatListView()
        .environment(ChatStore())
        .environment(AppSettings())
}
