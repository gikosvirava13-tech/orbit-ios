import OrbitCore
import OrbitUI
import SwiftUI

public enum AppTab: Hashable, CaseIterable {
    case chats
    case contacts
    case settings
}

/// The floating bar, assembled from live state. Each screen hosts its own copy
/// as a bottom safe-area inset rather than RootView overlaying one on top of
/// everything — that way pushing a conversation takes the bar away with it,
/// and the composer is never fighting a bar floating over it.
struct AppTabBar: View {
    @Environment(ChatStore.self) private var store
    @Environment(AppSettings.self) private var settings

    @Binding var selection: AppTab
    var onSearch: () -> Void

    var body: some View {
        FloatingTabBar(
            selection: $selection,
            items: [
                .init(
                    id: .chats,
                    title: "Chats",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    badge: settings.notificationsEnabled ? store.totalUnreadCount : 0
                ),
                .init(id: .contacts, title: "Contacts", systemImage: "person.crop.circle"),
                .init(id: .settings, title: "Settings", systemImage: "gearshape.fill")
            ],
            trailingAction: onSearch
        )
    }
}

public struct RootView: View {
    @Environment(AppSettings.self) private var settings

    @State private var tab: AppTab = .chats

    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            ChatListView(tab: $tab)
                .tag(AppTab.chats)
                .toolbar(.hidden, for: .tabBar)

            ContactsView(tab: $tab)
                .tag(AppTab.contacts)
                .toolbar(.hidden, for: .tabBar)

            SettingsView(tab: $tab)
                .tag(AppTab.settings)
                .toolbar(.hidden, for: .tabBar)
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

    @Binding var tab: AppTab

    @State private var search = ""
    @State private var isSearching = false
    @State private var path: [String] = []

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

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
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, isPresented: $isSearching, prompt: "Search")
            .overlay {
                if sections.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $tab) { isSearching = true }
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
