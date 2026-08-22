import TotemCore
import TotemUI
import SwiftUI

/// Destinations reachable from Settings. Modelled as a value so the whole
/// screen is one `navigationDestination`, and so a screenshot route can push
/// straight to any of them — including the ones two levels deep.
enum SettingsDestination: Hashable {
    case profile
    case saved
    case devices
    case folders
    case appearance
    case dataStorage
    case storage
    case notifications
    case privacy
    case blocked
    case language
    case help
    case about
}

/// One row in Settings, as data. Modelled rather than hand-written so the
/// search field can filter the same list the sections are built from.
struct SettingsEntry: Identifiable {
    let destination: SettingsDestination
    let title: String
    let symbol: String
    let tint: Color
    var value: String?
    var keywords: [String] = []

    var id: SettingsDestination { destination }

    func matches(_ query: String) -> Bool {
        let needle = query.lowercased()

        if title.lowercased().contains(needle) { return true }

        return keywords.contains { $0.lowercased().contains(needle) }
    }
}

struct SettingsGroup: Identifiable {
    let title: String
    let entries: [SettingsEntry]

    var id: String { title }
}

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ChatStore.self) private var store

    @Binding var tab: AppTab

    @State private var path: [SettingsDestination] = []
    @State private var query = ""
    @State private var isEditing = false
    @State private var isShowingCode = false
    @State private var isConfirmingReset = false

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                if query.isEmpty {
                    browse
                } else {
                    results
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search settings")
            .overlay {
                if !query.isEmpty, searchMatches.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingCode = true
                    } label: {
                        Label("Username code", systemImage: "qrcode")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { isEditing = true }
                }
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $tab) { tab = .chats }
            }
            .navigationDestination(for: SettingsDestination.self) { destination(for: $0) }
            .sheet(isPresented: $isEditing) { EditProfileView() }
            .sheet(isPresented: $isShowingCode) { UsernameCodeSheet() }
            .confirmationDialog(
                "Reset all settings?",
                isPresented: $isConfirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) { settings.reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your profile, appearance, privacy and download preferences go back to their defaults.")
            }
            .onAppear(perform: applyScreenshotRoute)
        }
    }

    // MARK: Content

    @ViewBuilder
    private var browse: some View {
        Section {
            VStack(spacing: 10) {
                heroCard
                quickActions
            }
            .plainCardRow()
        }

        ForEach(groups) { group in
            Section(group.title) {
                ForEach(group.entries) { row($0) }
            }
        }

        Section {
            LabeledContent("Chats", value: store.chats.count.formatted())
            LabeledContent("Missed Calls", value: store.missedCallCount.formatted())
            LabeledContent("Version", value: Self.appVersion)
        } header: {
            Text("Diagnostics")
        } footer: {
            Text("Totem is a design study. Messages live only on this device.")
        }

        Section {
            Button("Reset All Settings", role: .destructive) {
                isConfirmingReset = true
            }
        }
    }

    @ViewBuilder
    private var results: some View {
        Section {
            ForEach(searchMatches) { row($0) }
        } header: {
            Text(searchMatches.count == 1 ? "1 result" : "\(searchMatches.count) results")
        }
    }

    /// Who you are. Telegram and WhatsApp both lead with a name row; giving
    /// the actions their own tiles below keeps that row from carrying four
    /// jobs at once, and makes each shortcut look like something you press.
    private var heroCard: some View {
        SettingsCard {
            HStack(spacing: 14) {
                AvatarView(peer: mePeer, size: 62, showsPresence: false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.label)

                    Text(settings.username)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryLabel)

                    Text(settings.phoneNumber)
                        .font(.footnote)
                        .foregroundStyle(Theme.tertiaryLabel)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private var quickActions: some View {
        QuickActionRow {
            QuickActionButton(symbol: "person.crop.circle", title: "Profile") {
                path.append(.profile)
            }
            QuickActionButton(symbol: "square.and.pencil", title: "Edit") {
                isEditing = true
            }
            QuickActionButton(symbol: "qrcode", title: "Code") {
                isShowingCode = true
            }
            QuickActionButton(symbol: "bookmark", title: "Saved") {
                path.append(.saved)
            }
        }
    }

    private var mePeer: Peer {
        Peer(id: "me", name: settings.displayName, kind: .user, presence: .online)
    }

    /// One row shape for the whole screen: a tinted glyph tile, a title, an
    /// optional value, and a chevron — the iOS Settings idiom.
    private func row(_ entry: SettingsEntry) -> some View {
        NavigationLink(value: entry.destination) {
            LabeledContent {
                if let value = entry.value {
                    Text(value).foregroundStyle(Theme.secondaryLabel)
                }
            } label: {
                Label {
                    Text(entry.title)
                } icon: {
                    IconTile(symbol: entry.symbol, tint: entry.tint)
                }
            }
        }
        .accessibilityIdentifier("settings-\(entry.title)")
    }

    // MARK: Data

    /// Grouped by what the user is trying to change, rather than by the order
    /// the features happened to be built in.
    private var groups: [SettingsGroup] {
        [
            SettingsGroup(title: "Account", entries: [
                SettingsEntry(
                    destination: .profile,
                    title: "My Profile",
                    symbol: "person.crop.circle.fill",
                    tint: Theme.cobalt,
                    keywords: ["name", "bio", "username", "photo", "avatar"]
                ),
                SettingsEntry(
                    destination: .saved,
                    title: "Saved Messages",
                    symbol: "bookmark.fill",
                    tint: Theme.amber,
                    keywords: ["notes", "bookmarks", "later"]
                ),
                SettingsEntry(
                    destination: .devices,
                    title: "Devices",
                    symbol: "laptopcomputer.and.iphone",
                    tint: Theme.iris,
                    value: "2",
                    keywords: ["sessions", "desktop", "linked", "sign out"]
                )
            ]),

            SettingsGroup(title: "Conversations", entries: [
                SettingsEntry(
                    destination: .folders,
                    title: "Chat Folders",
                    symbol: "folder.fill",
                    tint: Theme.lagoon,
                    value: ChatListFilter.allCases.count.formatted(),
                    keywords: ["filters", "groups", "channels", "unread"]
                ),
                SettingsEntry(
                    destination: .appearance,
                    title: "Appearance",
                    symbol: "paintbrush.fill",
                    tint: Theme.orchid,
                    value: settings.accent.title,
                    keywords: ["theme", "dark", "light", "colour", "color", "wallpaper", "text size"]
                ),
                SettingsEntry(
                    destination: .dataStorage,
                    title: "Data and Storage",
                    symbol: "internaldrive.fill",
                    tint: Theme.aurora,
                    value: StorageUsage.totalFormatted,
                    keywords: ["cache", "download", "media", "wi-fi", "photos"]
                )
            ]),

            SettingsGroup(title: "Alerts and Privacy", entries: [
                SettingsEntry(
                    destination: .notifications,
                    title: "Notifications and Sounds",
                    symbol: "bell.badge.fill",
                    tint: Theme.coral,
                    value: settings.notificationsEnabled ? nil : "Off",
                    keywords: ["alerts", "badge", "sound", "vibrate", "mute", "previews"]
                ),
                SettingsEntry(
                    destination: .privacy,
                    title: "Privacy and Security",
                    symbol: "lock.fill",
                    tint: Theme.slate,
                    keywords: ["blocked", "passcode", "last seen", "read receipts"]
                )
            ]),

            SettingsGroup(title: "App", entries: [
                SettingsEntry(
                    destination: .language,
                    title: "Language",
                    symbol: "globe",
                    tint: Theme.lagoon,
                    value: settings.language.title,
                    keywords: ["translate", "locale", "region"]
                ),
                SettingsEntry(
                    destination: .help,
                    title: "Help",
                    symbol: "questionmark.circle.fill",
                    tint: Theme.cobalt,
                    keywords: ["faq", "support", "bug", "contact"]
                ),
                SettingsEntry(
                    destination: .about,
                    title: "About Totem",
                    symbol: "info.circle.fill",
                    tint: Theme.slate,
                    value: Self.appVersion,
                    keywords: ["version", "licences", "licenses", "terms", "privacy policy"]
                )
            ])
        ]
    }

    private var searchMatches: [SettingsEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return [] }

        return groups.flatMap(\.entries).filter { $0.matches(trimmed) }
    }

    @ViewBuilder
    private func destination(for value: SettingsDestination) -> some View {
        switch value {
        case .profile: ProfileView()
        case .saved: SavedMessagesView()
        case .devices: DevicesView()
        case .folders: ChatFoldersView()
        case .appearance: AppearanceSettingsView()
        case .dataStorage: DataStorageSettingsView()
        case .storage: StorageDetailView()
        case .notifications: NotificationsSettingsView()
        case .privacy: PrivacySettingsView()
        case .blocked: BlockedUsersView()
        case .language: LanguageSettingsView()
        case .help: HelpView()
        case .about: AboutView()
        }
    }

    // MARK: Screenshot routing

    /// CI launches the app with `-uiRoute storage` and lands on that screen,
    /// pushing however many levels it takes to get there.
    private func applyScreenshotRoute() {
        guard path.isEmpty, let route = ScreenshotRoute.current else { return }

        switch route {
        case .editProfile: isEditing = true
        case .qrCode: isShowingCode = true
        case .profile: path = [.profile]
        case .saved: path = [.saved]
        case .devices: path = [.devices]
        case .folders: path = [.folders]
        case .appearance: path = [.appearance]
        case .dataStorage: path = [.dataStorage]
        case .storage: path = [.dataStorage, .storage]
        case .notifications: path = [.notifications]
        case .privacy: path = [.privacy]
        case .blocked: path = [.privacy, .blocked]
        case .language: path = [.language]
        case .help: path = [.help]
        case .about: path = [.about]
        default: break
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"

        return "\(short) (\(build))"
    }
}

#Preview {
    struct Harness: View {
        @State private var tab: AppTab = .settings

        var body: some View {
            SettingsView(tab: $tab)
        }
    }

    return Harness()
        .environment(AppSettings())
        .environment(ChatStore())
}
