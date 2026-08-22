import OrbitCore
import OrbitUI
import SwiftUI

// MARK: - Notifications

struct NotificationsSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ChatStore.self) private var store

    var body: some View {
        @Bindable var settings = settings

        List {
            Section {
                NotificationPreviewCard(
                    isEnabled: settings.notificationsEnabled,
                    showsPreview: settings.showMessagePreviews,
                    sender: previewChat?.peer.name ?? "Nadia Rahman",
                    text: previewChat?.previewText ?? "Sent you a message"
                )
                .plainCardRow()
            } footer: {
                Text("This is how an alert looks on your Lock Screen right now.")
            }

            Section {
                Toggle("Allow Notifications", isOn: $settings.notificationsEnabled)
            } footer: {
                Text("Turning this off silences every badge and alert, including the tab bar count.")
            }

            Section("Message Alerts") {
                Toggle("Show Previews", isOn: $settings.showMessagePreviews)
                Toggle("In-App Sounds", isOn: $settings.inAppSounds)
                Toggle("In-App Vibrate", isOn: $settings.inAppVibrate)
            }
            .disabled(!settings.notificationsEnabled)

            Section {
                Toggle("Count Muted Chats", isOn: $settings.countMutedChats)
            } header: {
                Text("Badge")
            } footer: {
                Text("Include chats you have muted in the unread count on the tab bar.")
            }
            .disabled(!settings.notificationsEnabled)

            Section {
                if mutedChats.isEmpty {
                    Text("No exceptions")
                        .foregroundStyle(Theme.secondaryLabel)
                } else {
                    ForEach(mutedChats) { chat in
                        exceptionRow(chat)
                    }
                }
            } header: {
                Text("Muted Chats")
            } footer: {
                Text("Muted conversations never alert you, whatever the settings above say.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications and Sounds")
        .navigationBarTitleDisplayMode(.inline)
        .animation(Motion.standard, value: settings.showMessagePreviews)
        .animation(Motion.standard, value: settings.notificationsEnabled)
    }

    private var mutedChats: [Chat] {
        store.chats.filter(\.isMuted).sorted { $0.peer.name < $1.peer.name }
    }

    private var previewChat: Chat? {
        store.chats.first { $0.peer.kind == .user && !$0.messages.isEmpty }
    }

    /// `.borderless` so the trailing button is hit independently — a plain
    /// button inside a list row otherwise hands the whole row to the first one.
    private func exceptionRow(_ chat: Chat) -> some View {
        HStack(spacing: 12) {
            AvatarView(peer: chat.peer, size: 32, showsPresence: false)

            VStack(alignment: .leading, spacing: 1) {
                Text(chat.peer.name)
                Text("Muted")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
            }

            Spacer(minLength: 8)

            Button("Unmute") {
                store.toggleMuted(chatID: chat.id)
            }
            .buttonStyle(.borderless)
            .font(.subheadline.weight(.medium))
        }
    }
}

/// A stand-in Lock Screen banner that reacts to the toggles below it, so the
/// effect of "Show Previews" is visible before you leave the screen.
struct NotificationPreviewCard: View {
    let isEnabled: Bool
    let showsPreview: Bool
    let sender: String
    let text: String

    var body: some View {
        SettingsCard {
            HStack(alignment: .top, spacing: 12) {
                IconTile(symbol: "bubble.left.and.bubble.right.fill", tint: Color.accentColor, side: 38)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("ORBIT")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.secondaryLabel)

                        Spacer(minLength: 0)

                        Text("now")
                            .font(.caption2)
                            .foregroundStyle(Theme.tertiaryLabel)
                    }

                    Text(headline)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryLabel)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(14)
        }
        .opacity(isEnabled ? 1 : 0.45)
        .saturation(isEnabled ? 1 : 0)
    }

    private var headline: String {
        guard isEnabled else { return "Notifications are off" }

        return showsPreview ? sender : "Orbit"
    }

    private var detail: String {
        guard isEnabled else { return "You will not be alerted about new messages." }

        return showsPreview ? text : "1 new message"
    }
}

// MARK: - Privacy

struct PrivacySettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        List {
            Section {
                summaryCard.plainCardRow()
            }

            Section {
                audienceRow("Last Seen", symbol: "clock", selection: $settings.lastSeenVisibility)
                audienceRow("Profile Photo", symbol: "person.crop.square", selection: $settings.photoVisibility)
                audienceRow("Group Invites", symbol: "person.2", selection: $settings.groupInviteAudience)
            } header: {
                Text("Who Can See")
            } footer: {
                Text("Limiting what you share also limits what you can see about other people.")
            }

            Section {
                Toggle("Read Receipts", isOn: $settings.readReceiptsEnabled)
            } header: {
                Text("Messaging")
            } footer: {
                Text("When off, delivery ticks are hidden everywhere — in conversations and in the chat list.")
            }

            Section {
                Toggle("Passcode Lock", isOn: $settings.passcodeEnabled)
                NavigationLink(value: SettingsDestination.blocked) {
                    Text("Blocked Users")
                }
            } header: {
                Text("Security")
            } footer: {
                Text("A passcode is requested whenever the app returns from the background.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Privacy and Security")
        .navigationBarTitleDisplayMode(.inline)
        .animation(Motion.standard, value: settings.passcodeEnabled)
    }

    /// One sentence describing the current posture, rather than repeating the
    /// rows underneath as a set of chips.
    private var summaryCard: some View {
        SettingsCard {
            HStack(spacing: 14) {
                Image(systemName: settings.passcodeEnabled ? "lock.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.passcodeEnabled ? "Locked" : "Standard Protection")
                        .font(.headline)

                    Text(summaryText)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private var summaryText: String {
        let seen = settings.lastSeenVisibility.title.lowercased()
        let receipts = settings.readReceiptsEnabled ? "on" : "off"

        return "Last seen is visible to \(seen), and read receipts are \(receipts)."
    }

    private func audienceRow(
        _ title: String,
        symbol: String,
        selection: Binding<PrivacyAudience>
    ) -> some View {
        NavigationLink {
            AudiencePicker(title: title, selection: selection)
        } label: {
            LabeledContent {
                Text(selection.wrappedValue.title)
            } label: {
                Label(title, systemImage: symbol)
            }
        }
    }
}

struct AudiencePicker: View {
    let title: String
    @Binding var selection: PrivacyAudience

    var body: some View {
        List {
            Section {
                // Checkmark rows rather than a `Picker`, because that is what
                // iOS shows when a choice gets a screen of its own.
                ForEach(PrivacyAudience.allCases) { option in
                    Button {
                        selection = option
                    } label: {
                        HStack {
                            Text(option.title)
                                .foregroundStyle(Theme.label)

                            Spacer()

                            if option == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(.rect)
                    }
                }
            } header: {
                Text("Who can see this")
            } footer: {
                Text(footerText)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .animation(Motion.quick, value: selection)
    }

    private var footerText: String {
        switch selection {
        case .everybody: "Anyone who has your username can see this."
        case .contacts: "Only people saved in your contacts can see this."
        case .nobody: "Nobody can see this, and you will not see it about others."
        }
    }
}

struct BlockedUsersView: View {
    var body: some View {
        List {
            Section {
                SettingsCard {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Color.accentColor)

                        Text("Nobody is blocked")
                            .font(.headline)

                        Text("Blocked people cannot message or call you, and cannot see when you were last online.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(24)
                }
                .plainCardRow()
            }

            Section {
                Button {
                    // A contact picker would open here.
                } label: {
                    Label("Block a Contact", systemImage: "plus.circle.fill")
                }
            } footer: {
                Text("You can also block someone from their profile.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Notifications") {
    NavigationStack {
        NotificationsSettingsView()
            .environment(AppSettings())
            .environment(ChatStore())
    }
}

#Preview("Privacy") {
    NavigationStack {
        PrivacySettingsView()
            .environment(AppSettings())
    }
}
