import TotemCore
import TotemUI
import SwiftUI

// MARK: - Devices

struct DevicesView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isConfirmingSignOut = false

    var body: some View {
        List {
            Section {
                currentDeviceCard.plainCardRow()
            }

            Section {
                Button {
                    // A scanner would open here.
                } label: {
                    Label("Link a Desktop App", systemImage: "qrcode.viewfinder")
                }
            } footer: {
                Text("Scan the code shown on the desktop app to sign in without typing your number.")
            }

            Section {
                ForEach(Self.otherSessions) { session in
                    sessionRow(session)
                }
            } header: {
                Text("Active Sessions")
            } footer: {
                Text("Signing a device out does not delete anything already downloaded to it.")
            }

            Section {
                Button("Sign Out All Other Devices", role: .destructive) {
                    isConfirmingSignOut = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Sign out everywhere else?",
            isPresented: $isConfirmingSignOut,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This device stays signed in. Every other session ends immediately.")
        }
    }

    private var currentDeviceCard: some View {
        SettingsCard {
            VStack(spacing: 10) {
                Image(systemName: "iphone")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color.accentColor)

                Text("This iPhone")
                    .font(.headline)

                Text("Signed in as \(settings.username)")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.online)
                        .frame(width: 7, height: 7)

                    Text("Active now")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryLabel)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.incomingBubble, in: Capsule())
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
        }
    }

    private func sessionRow(_ session: DeviceSession) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: session.symbol, tint: session.tint, side: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)

                Text(session.detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
            }

            Spacer(minLength: 8)

            Button("End") {}
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.destructive)
        }
    }

    private static let otherSessions: [DeviceSession] = [
        DeviceSession(
            id: "mac",
            name: "MacBook Air",
            detail: "Totem Desktop 1.0 - 2 hours ago",
            symbol: "laptopcomputer",
            tint: Theme.iris
        ),
        DeviceSession(
            id: "web",
            name: "Safari on iPad",
            detail: "Totem Web - yesterday",
            symbol: "safari",
            tint: Theme.cobalt
        )
    ]
}

private struct DeviceSession: Identifiable {
    let id: String
    let name: String
    let detail: String
    let symbol: String
    let tint: Color
}

// MARK: - Chat folders

struct ChatFoldersView: View {
    @Environment(ChatStore.self) private var store

    var body: some View {
        List {
            Section {
                SettingsCard {
                    HStack(spacing: 14) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 44)

                        Text("Folders appear as scopes under the search field on the Chats screen.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(16)
                }
                .plainCardRow()
            }

            Section {
                ForEach(ChatListFilter.allCases) { filter in
                    LabeledContent {
                        Text(count(for: filter).formatted())
                            .foregroundStyle(Theme.secondaryLabel)
                            .monospacedDigit()
                    } label: {
                        Label {
                            Text(filter.rawValue)
                        } icon: {
                            IconTile(symbol: symbol(for: filter), tint: tint(for: filter))
                        }
                    }
                }
            } header: {
                Text("Your Folders")
            }

            Section {
                Button {
                    // A folder editor would open here.
                } label: {
                    Label("Create New Folder", systemImage: "plus.circle.fill")
                }
            } footer: {
                Text("A folder collects chats by rule — by type, by unread state, or by the people in them.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Chat Folders")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func count(for filter: ChatListFilter) -> Int {
        store.sorted(filter: filter, search: "").count
    }

    private func symbol(for filter: ChatListFilter) -> String {
        switch filter {
        case .all: "tray.full.fill"
        case .unread: "envelope.badge.fill"
        case .groups: "person.2.fill"
        case .channels: "megaphone.fill"
        }
    }

    private func tint(for filter: ChatListFilter) -> Color {
        switch filter {
        case .all: Theme.cobalt
        case .unread: Theme.aurora
        case .groups: Theme.amber
        case .channels: Theme.orchid
        }
    }
}

// MARK: - Language

struct LanguageSettingsView: View {
    @Environment(AppSettings.self) private var settings

    @State private var query = ""

    var body: some View {
        List {
            Section {
                ForEach(matches) { language in
                    Button {
                        settings.language = language
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(language.title)
                                    .foregroundStyle(Theme.label)

                                Text(language.nativeTitle)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.secondaryLabel)
                            }

                            Spacer()

                            if language == settings.language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(.rect)
                    }
                }
            } footer: {
                Text("Interface text only. Messages are never translated for you.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Search languages")
        .overlay {
            if matches.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .animation(Motion.quick, value: settings.language)
    }

    private var matches: [AppLanguage] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmed.isEmpty else { return AppLanguage.allCases }

        return AppLanguage.allCases.filter {
            $0.title.lowercased().contains(trimmed) || $0.nativeTitle.lowercased().contains(trimmed)
        }
    }
}

// MARK: - Help

/// Answers open in place rather than pushing a screen each — there is one
/// paragraph behind every one of these, and a push for a paragraph is a lot.
struct HelpView: View {
    @State private var expanded: String?

    var body: some View {
        List {
            Section {
                SettingsCard {
                    VStack(spacing: 8) {
                        Image(systemName: "lifepreserver.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.accentColor)

                        Text("How can we help?")
                            .font(.headline)

                        Text("Most questions are answered below. If yours is not, send us a note and we will read it.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(20)
                }
                .plainCardRow()
            }

            Section {
                ForEach(Self.questions) { item in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expanded == item.id },
                            set: { expanded = $0 ? item.id : nil }
                        )
                    ) {
                        Text(item.answer)
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryLabel)
                            .padding(.vertical, 4)
                    } label: {
                        Text(item.question)
                    }
                }
            } header: {
                Text("Common Questions")
            }

            Section {
                Label("Email Support", systemImage: "envelope.fill")
                Label("Report a Bug", systemImage: "ladybug.fill")
                Label("Feature Requests", systemImage: "lightbulb.fill")
            } header: {
                Text("Get in Touch")
            } footer: {
                Text("Support replies land in Saved Messages so you do not lose them.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        .animation(Motion.standard, value: expanded)
    }

    private struct Question: Identifiable {
        let id: String
        let question: String
        let answer: String
    }

    private static let questions: [Question] = [
        Question(
            id: "sync",
            question: "Where are my messages stored?",
            answer: "On this device only. Totem is a design study, so there is no server behind it yet and nothing leaves your phone."
        ),
        Question(
            id: "receipts",
            question: "Can I hide read receipts?",
            answer: "Yes. Privacy and Security has a Read Receipts switch. Turning it off hides the ticks in conversations and in the chat list at the same time."
        ),
        Question(
            id: "mute",
            question: "What is the difference between muting and blocking?",
            answer: "Muting silences a conversation but leaves it in your list. Blocking stops that person reaching you at all."
        ),
        Question(
            id: "storage",
            question: "Why is Totem using storage?",
            answer: "Downloaded photos, videos and files are cached so they open instantly. Manage Storage shows which conversations hold the most."
        )
    ]
}

// MARK: - About

struct AboutView: View {
    var body: some View {
        List {
            Section {
                SettingsCard {
                    VStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.accentColor)
                            .frame(width: 84, height: 84)
                            .overlay {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.white)
                            }

                        Text("Totem")
                            .font(.title2.weight(.semibold))

                        Text("Version \(Self.version)")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                    .padding(.vertical, 22)
                    .padding(.horizontal, 16)
                }
                .plainCardRow()
            }

            Section {
                Label("What's New", systemImage: "sparkles")
                Label("Privacy Policy", systemImage: "hand.raised.fill")
                Label("Terms of Service", systemImage: "doc.text.fill")
                Label("Open Source Licences", systemImage: "shippingbox.fill")
            }

            Section {
                LabeledContent("Build", value: Self.build)
                LabeledContent("Platform", value: "iOS 17 and later")
            } footer: {
                Text("Built with SwiftUI. Layout borrowed from apps that got it right; the components are our own.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About Totem")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Saved messages

/// Anything you send yourself. Sourced from real outgoing messages so the
/// screen has something honest in it rather than a placeholder.
struct SavedMessagesView: View {
    @Environment(ChatStore.self) private var store

    var body: some View {
        List {
            if saved.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Saved Messages",
                        systemImage: "bookmark",
                        description: Text("Forward a message here to keep it handy.")
                    )
                    .plainCardRow()
                }
            } else {
                Section {
                    ForEach(saved) { item in
                        row(item)
                    }
                } header: {
                    Text("Recently Saved")
                } footer: {
                    Text("Saved messages stay on this device and are never shown to anyone else.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Saved Messages")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct SavedItem: Identifiable {
        let id: String
        let source: String
        let text: String
        let date: Date
    }

    private var saved: [SavedItem] {
        store.chats
            .flatMap { chat in
                chat.messages
                    .filter { $0.isOutgoing && $0.text.count > 12 }
                    .map { SavedItem(id: $0.id, source: chat.peer.name, text: $0.text, date: $0.date) }
            }
            .sorted { $0.date > $1.date }
            .prefix(6)
            .map { $0 }
    }

    private func row(_ item: SavedItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .font(.caption2)

                Text(item.source)
                    .font(.caption.weight(.medium))

                Spacer(minLength: 8)

                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(Theme.tertiaryLabel)
            }
            .foregroundStyle(Theme.secondaryLabel)

            Text(item.text)
                .font(.subheadline)
                .foregroundStyle(Theme.label)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Devices") {
    NavigationStack {
        DevicesView().environment(AppSettings())
    }
}

#Preview("Help") {
    NavigationStack {
        HelpView()
    }
}

#Preview("Saved") {
    NavigationStack {
        SavedMessagesView().environment(ChatStore())
    }
}
