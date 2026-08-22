import OrbitCore
import OrbitUI
import SwiftUI

// MARK: - Notifications

struct NotificationsSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
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
            } footer: {
                Text("Include chats you have muted in the unread badge.")
            }
            .disabled(!settings.notificationsEnabled)
        }
        .navigationTitle("Notifications and Sounds")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy

struct PrivacySettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                Toggle("Read Receipts", isOn: $settings.readReceiptsEnabled)
            } footer: {
                Text("When off, delivery ticks are hidden everywhere — in conversations and in the chat list.")
            }

            Section("Who Can See") {
                NavigationLink {
                    VisibilityPicker(title: "Last Seen", selection: $settings.lastSeenVisibility)
                } label: {
                    LabeledContent("Last Seen", value: settings.lastSeenVisibility.title)
                }

                NavigationLink {
                    VisibilityPicker(title: "Profile Photo", selection: $settings.photoVisibility)
                } label: {
                    LabeledContent("Profile Photo", value: settings.photoVisibility.title)
                }
            }

            Section {
                Toggle("Passcode Lock", isOn: $settings.passcodeEnabled)
                NavigationLink("Blocked Users") { BlockedUsersView() }
            } footer: {
                Text("A passcode is requested whenever the app returns from the background.")
            }
        }
        .navigationTitle("Privacy and Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VisibilityPicker: View {
    let title: String
    @Binding var selection: Visibility

    var body: some View {
        Form {
            Section {
                // A List of checkmark rows rather than a Picker, because that
                // is what iOS shows for this kind of choice on its own screen.
                ForEach(Visibility.allCases) { option in
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
                    }
                }
            } footer: {
                Text("Changing this also changes what you can see about other people.")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BlockedUsersView: View {
    var body: some View {
        List {
            ContentUnavailableView(
                "No Blocked Users",
                systemImage: "hand.raised",
                description: Text("Blocked users cannot message or call you.")
            )
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance

struct AppearanceSettingsView: View {
    @Environment(AppSettings.self) private var settings

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 16)]

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Theme") {
                Picker("Theme", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
            }

            Section {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AccentPalette.allCases) { palette in
                        Button {
                            settings.accent = palette
                        } label: {
                            Circle()
                                .fill(palette.color)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if palette == settings.accent {
                                        Image(systemName: "checkmark")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(palette.title)
                        .accessibilityAddTraits(palette == settings.accent ? .isSelected : [])
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Accent Colour")
            } footer: {
                Text("Applies across the app — buttons, links, the tab bar and outgoing bubbles.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data and storage

struct DataStorageSettingsView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isClearing = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Automatic Download") {
                policyRow("Photos", selection: $settings.photoDownload)
                policyRow("Videos", selection: $settings.videoDownload)
                policyRow("Files", selection: $settings.fileDownload)
            }

            Section {
                Toggle("Save Incoming Photos", isOn: $settings.saveIncomingToPhotos)
            } footer: {
                Text("Photos you receive are added to your photo library automatically.")
            }

            Section("Storage") {
                LabeledContent("Cache", value: settings.approximateCacheSize)
                Button("Clear Cache", role: .destructive) { isClearing = true }
            }
        }
        .navigationTitle("Data and Storage")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear cached media?", isPresented: $isClearing, titleVisibility: .visible) {
            Button("Clear Cache", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Messages stay; downloaded media is fetched again when you open it.")
        }
    }

    private func policyRow(_ title: String, selection: Binding<AutoDownloadPolicy>) -> some View {
        Picker(title, selection: selection) {
            ForEach(AutoDownloadPolicy.allCases) { policy in
                Text(policy.title).tag(policy)
            }
        }
    }
}

// MARK: - Devices

struct DevicesView: View {
    var body: some View {
        Form {
            Section("This Device") {
                DeviceRow(name: "iPhone", detail: "Orbit 1.0 · active now", symbol: "iphone")
            }

            Section {
                DeviceRow(name: "Mac", detail: "Orbit Desktop · 2 hours ago", symbol: "laptopcomputer")
            } header: {
                Text("Active Sessions")
            } footer: {
                Text("Signing out of a device does not delete anything from it.")
            }

            Section {
                Button("Sign Out All Other Devices", role: .destructive) {}
            }
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DeviceRow: View {
    let name: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
            }
        }
    }
}

// MARK: - Chat folders

struct ChatFoldersView: View {
    @Environment(ChatStore.self) private var store

    var body: some View {
        Form {
            Section {
                ForEach(ChatListFilter.allCases) { filter in
                    LabeledContent(filter.rawValue) {
                        Text(store.sorted(filter: filter, search: "").count.formatted())
                            .foregroundStyle(Theme.secondaryLabel)
                    }
                }
            } header: {
                Text("Folders")
            } footer: {
                Text("Folders appear as scopes under the search field on the Chats screen.")
            }
        }
        .navigationTitle("Chat Folders")
        .navigationBarTitleDisplayMode(.inline)
    }
}
