import OrbitCore
import OrbitUI
import SwiftUI

/// Destinations reachable from Settings. Modelled as a value so the whole
/// screen is one `navigationDestination`, and so a screenshot route can push
/// straight to any of them.
enum SettingsDestination: Hashable {
    case profile
    case notifications
    case privacy
    case appearance
    case dataStorage
    case devices
    case folders
    case saved
}

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ChatStore.self) private var store

    @Binding var tab: AppTab

    @State private var path: [SettingsDestination] = []
    @State private var isEditing = false
    @State private var isShowingCode = false
    @State private var isConfirmingReset = false

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Button {
                        // A photo picker would open here.
                    } label: {
                        Label("Change Profile Photo", systemImage: "camera.on.rectangle")
                    }
                }

                Section {
                    row(.profile, "My Profile", "person.crop.circle.fill", Color(.systemRed))
                    row(.saved, "Saved Messages", "bookmark.fill", Color(.systemBlue))
                }

                Section {
                    row(.folders, "Chat Folders", "folder.fill", Color(.systemCyan))
                    row(.devices, "Devices", "laptopcomputer.and.iphone", Color(.systemOrange), value: "2")
                }

                Section {
                    row(.notifications, "Notifications and Sounds", "bell.badge.fill", Color(.systemRed))
                    row(.privacy, "Privacy and Security", "lock.fill", Color(.systemGray))
                    row(.dataStorage, "Data and Storage", "cylinder.split.1x2.fill", Color(.systemGreen))
                    row(.appearance, "Appearance", "circle.lefthalf.filled", Color(.systemBlue))
                }

                Section {
                    LabeledContent("Chats", value: store.chats.count.formatted())
                    LabeledContent("Missed Calls", value: store.missedCallCount.formatted())
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Orbit is a design study. Messages live only on this device.")
                }

                Section {
                    Button("Reset All Settings", role: .destructive) {
                        isConfirmingReset = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(settings.displayName)
            .navigationBarTitleDisplayMode(.inline)
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
            .navigationDestination(for: SettingsDestination.self) { destination($0) }
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
            .onAppear {
                if ScreenshotRoute.current == .profile, path.isEmpty {
                    path = [.profile]
                }
            }
        }
    }

    /// One row shape for the whole screen: a tinted glyph tile, a title, an
    /// optional value, and a chevron — the iOS Settings idiom.
    private func row(
        _ destination: SettingsDestination,
        _ title: String,
        _ symbol: String,
        _ tint: Color,
        value: String? = nil
    ) -> some View {
        NavigationLink(value: destination) {
            LabeledContent {
                if let value {
                    Text(value).foregroundStyle(Theme.secondaryLabel)
                }
            } label: {
                Label {
                    Text(title)
                } icon: {
                    IconTile(symbol: symbol, tint: tint)
                }
            }
        }
    }

    @ViewBuilder
    private func destination(_ destination: SettingsDestination) -> some View {
        switch destination {
        case .profile: ProfileView()
        case .notifications: NotificationsSettingsView()
        case .privacy: PrivacySettingsView()
        case .appearance: AppearanceSettingsView()
        case .dataStorage: DataStorageSettingsView()
        case .devices: DevicesView()
        case .folders: ChatFoldersView()
        case .saved: SavedMessagesView()
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"

        return "\(short) (\(build))"
    }
}

struct SavedMessagesView: View {
    var body: some View {
        ContentUnavailableView(
            "No Saved Messages",
            systemImage: "bookmark",
            description: Text("Forward messages here to keep them handy.")
        )
        .navigationTitle("Saved Messages")
        .navigationBarTitleDisplayMode(.inline)
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
