import OrbitCore
import OrbitUI
import SwiftUI

/// Tab container. Built from a stock `TabView`, so on iOS 26 the system draws
/// it with Liquid Glass and handles the scroll-edge behaviour itself — there is
/// no custom bar to get wrong.
public struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ChatStore.self) private var store

    public init() {}

    public var body: some View {
        TabView {
            ChatListView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .badge(settings.notificationsEnabled ? store.totalUnreadCount : 0)

            ContactsView()
                .tabItem {
                    Label("Contacts", systemImage: "person.crop.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// People you have a direct conversation with, grouped the way Contacts does.
public struct ContactsView: View {
    @Environment(ChatStore.self) private var store

    @State private var search = ""
    @State private var path: [String] = []

    public init() {}

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(sections, id: \.letter) { section in
                    Section(section.letter) {
                        ForEach(section.chats) { chat in
                            Button {
                                store.markRead(chatID: chat.id)
                                path.append(chat.id)
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
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Contacts")
            .searchable(text: $search, prompt: "Search")
            .overlay {
                if sections.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .navigationDestination(for: String.self) { chatID in
                ConversationView(chatID: chatID)
            }
        }
    }

    private var sections: [(letter: String, chats: [Chat])] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let people = store.chats
            .filter { $0.peer.kind == .user }
            .filter { query.isEmpty || $0.peer.name.lowercased().contains(query) }
            .sorted { $0.peer.name < $1.peer.name }

        return Dictionary(grouping: people) { String($0.peer.name.prefix(1)).uppercased() }
            .map { (letter: $0.key, chats: $0.value) }
            .sorted { $0.letter < $1.letter }
    }
}

#Preview {
    RootView()
        .environment(AppSettings())
        .environment(ChatStore())
}
