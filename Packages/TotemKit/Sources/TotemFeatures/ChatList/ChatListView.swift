import TotemCore
import TotemUI
import SwiftUI

public struct ChatListView: View {
    @Environment(ChatStore.self) private var store

    @Binding var tab: AppTab

    @State private var search = ""
    @State private var isSearching = false
    @State private var scope: ChatListFilter = .all
    @State private var path: [String] = []
    @State private var isComposing = false

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

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
                    .accessibilityIdentifier("chat-\(chat.id)")
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
                        .tint(Theme.amber)
                    }
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            // Inline keeps the title centred between the leading Edit control
            // and the trailing actions, which is where the eye expects it once
            // there is a control on both sides.
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search,
                isPresented: $isSearching,
                prompt: "Search chats and messages"
            )
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
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                // On iOS 26 the system renders toolbar items as Liquid Glass
                // and merges a group into one capsule, so this needs no
                // styling of its own.
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposing = true
                    } label: {
                        Label("New chat", systemImage: "square.and.pencil")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $tab) { isSearching = true }
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
            .onAppear(perform: applyScreenshotRoute)
        }
    }

    private var visibleChats: [Chat] {
        store.sorted(filter: search.isEmpty ? .all : scope, search: search)
    }

    /// CI launches the app with `-uiRoute conversation` (or `newChat`) so it
    /// can photograph those screens without driving the UI.
    private func applyScreenshotRoute() {
        guard let route = ScreenshotRoute.current else { return }

        switch route {
        case .conversation where path.isEmpty:
            path = [ScreenshotRoute.sampleChatID]
        case .newChat:
            isComposing = true
        default:
            break
        }
    }

    private func delete(at offsets: IndexSet) {
        // The list is filtered and sorted, so offsets are resolved against what
        // is on screen rather than against the store's own order.
        store.delete(chatIDs: offsets.map { visibleChats[$0].id })
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
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    struct Harness: View {
        @State private var tab: AppTab = .chats

        var body: some View {
            ChatListView(tab: $tab)
        }
    }

    return Harness()
        .environment(ChatStore())
        .environment(AppSettings())
}
