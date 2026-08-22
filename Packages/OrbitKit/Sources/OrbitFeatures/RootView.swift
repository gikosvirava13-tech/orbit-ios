import OrbitCore
import OrbitUI
import SwiftUI

public enum AppTab: Hashable, CaseIterable {
    case contacts
    case calls
    case chats
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
                .init(id: .contacts, title: "Contacts", systemImage: "person.crop.circle.fill"),
                .init(
                    id: .calls,
                    title: "Calls",
                    systemImage: "phone.fill",
                    badge: settings.notificationsEnabled ? store.missedCallCount : 0
                ),
                .init(
                    id: .chats,
                    title: "Chats",
                    systemImage: "bubble.left.and.bubble.right.fill",
                    badge: settings.notificationsEnabled ? unreadBadge : 0
                ),
                .init(id: .settings, title: "Settings", systemImage: "gearshape.fill")
            ],
            trailingAction: onSearch
        )
    }

    /// Muted chats only count when the user asks for them to.
    private var unreadBadge: Int {
        settings.countMutedChats
            ? store.chats.reduce(0) { $0 + $1.unreadCount }
            : store.totalUnreadCount
    }
}

public struct RootView: View {
    @Environment(AppSettings.self) private var settings

    @State private var tab: AppTab = RootView.initialTab

    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            ContactsView(tab: $tab)
                .tag(AppTab.contacts)
                .toolbar(.hidden, for: .tabBar)

            CallsView(tab: $tab)
                .tag(AppTab.calls)
                .toolbar(.hidden, for: .tabBar)

            ChatListView(tab: $tab)
                .tag(AppTab.chats)
                .toolbar(.hidden, for: .tabBar)

            SettingsView(tab: $tab)
                .tag(AppTab.settings)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(settings.accent.color)
        .preferredColorScheme(colorScheme)
    }

    private static var initialTab: AppTab {
        switch ScreenshotRoute.current {
        case .calls: .calls
        case .contacts: .contacts
        case .settings, .profile: .settings
        default: .chats
        }
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
    @State private var sortByName = true
    @State private var path: [String] = []

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Button {
                        // An invite sheet would open here.
                    } label: {
                        Label("Invite Friends", systemImage: "person.crop.circle.badge.plus")
                            .foregroundStyle(Color.accentColor)
                    }
                }

                ForEach(sections) { section in
                    Section(section.title) {
                        ForEach(section.chats) { chat in
                            Button {
                                store.markRead(chatID: chat.id)
                                path.append(chat.id)
                            } label: {
                                HStack(spacing: 12) {
                                    AvatarView(peer: chat.peer, size: 40)

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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu("Sort") {
                        Picker("Sort", selection: $sortByName) {
                            Text("By Name").tag(true)
                            Text("By Last Seen").tag(false)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // A new-contact form would open here.
                    } label: {
                        Label("Add Contact", systemImage: "plus")
                    }
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

    /// A named type, not a tuple: `ForEach` needs `Identifiable`, and Swift
    /// has no key paths into tuple elements.
    struct ContactSection: Identifiable {
        let title: String
        let chats: [Chat]

        var id: String { title }
    }

    private var sections: [ContactSection] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let people = store.chats
            .filter { $0.peer.kind == .user }
            .filter { query.isEmpty || $0.peer.name.lowercased().contains(query) }

        guard sortByName else {
            return [ContactSection(
                title: "Sorted by Last Seen",
                chats: people.sorted { $0.date > $1.date }
            )]
        }

        return Dictionary(grouping: people.sorted { $0.peer.name < $1.peer.name }) {
            String($0.peer.name.prefix(1)).uppercased()
        }
        .map { ContactSection(title: $0.key, chats: $0.value) }
        .sorted { $0.title < $1.title }
    }
}

#Preview {
    RootView()
        .environment(AppSettings())
        .environment(ChatStore())
}
