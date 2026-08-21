import OrbitCore
import OrbitUI
import SwiftUI

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ChatStore.self) private var store

    @State private var isEditingProfile = false

    public init() {}

    public var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                Section {
                    Button {
                        isEditingProfile = true
                    } label: {
                        profileRow
                    }
                    .buttonStyle(.plain)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle(isOn: $settings.readReceiptsEnabled) {
                        Label("Read Receipts", systemImage: "checkmark.circle")
                    }
                    Toggle(isOn: $settings.notificationsEnabled) {
                        Label("Notifications", systemImage: "bell.badge")
                    }
                } header: {
                    Text("Chats")
                } footer: {
                    Text("Turning off read receipts hides delivery ticks everywhere, including the chat list.")
                }

                Section("About") {
                    LabeledContent("Chats", value: store.chats.count.formatted())
                    LabeledContent("Groups", value: groupCount.formatted())
                    LabeledContent("Channels", value: channelCount.formatted())
                    LabeledContent("Version", value: appVersion)
                }

                Section {
                    Button("Reset All Settings", role: .destructive) {
                        settings.reset()
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isEditingProfile) {
                EditProfileSheet()
            }
        }
    }

    private var profileRow: some View {
        HStack(spacing: 14) {
            AvatarView(
                peer: Peer(id: "me", name: settings.displayName, kind: .user),
                size: 60,
                showsPresence: false
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(settings.displayName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.label)

                Text(settings.bio)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryLabel)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.tertiaryLabel)
        }
        .padding(.vertical, 6)
    }

    private var groupCount: Int {
        store.chats.filter { $0.peer.kind == .group }.count
    }

    private var channelCount: Int {
        store.chats.filter { $0.peer.kind == .channel }.count
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"

        return "\(short) (\(build))"
    }
}

struct EditProfileSheet: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }
                Section("Bio") {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

                        settings.displayName = trimmed.isEmpty ? settings.displayName : trimmed
                        settings.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                }
            }
            .onAppear {
                name = settings.displayName
                bio = settings.bio
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .environment(ChatStore())
}
