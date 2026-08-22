import Foundation
import Observation

// MARK: - Enums

public enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

public enum AccentPalette: String, CaseIterable, Identifiable, Sendable {
    case blue, purple, pink, orange, green, teal

    public var id: String { rawValue }

    public var title: String { rawValue.capitalized }
}

/// Who can see a given piece of profile information.
public enum Visibility: String, CaseIterable, Identifiable, Sendable {
    case everybody, contacts, nobody

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .everybody: "Everybody"
        case .contacts: "My Contacts"
        case .nobody: "Nobody"
        }
    }
}

public enum AutoDownloadPolicy: String, CaseIterable, Identifiable, Sendable {
    case always, wifiOnly, never

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .always: "Always"
        case .wifiOnly: "Wi-Fi Only"
        case .never: "Never"
        }
    }
}

// MARK: - Settings

/// Every user preference in the app, persisted to `UserDefaults`.
///
/// Lives in Core rather than the UI layer because several of these are
/// protocol-level concerns once a backend exists — read receipts and last-seen
/// visibility are things the server has to honour, not just things we hide.
@MainActor
@Observable
public final class AppSettings {
    // MARK: Profile

    public var displayName: String { didSet { save(displayName, .displayName) } }
    public var username: String { didSet { save(username, .username) } }
    public var phoneNumber: String { didSet { save(phoneNumber, .phoneNumber) } }
    public var bio: String { didSet { save(bio, .bio) } }

    // MARK: Appearance

    public var appearance: AppearanceMode { didSet { save(appearance.rawValue, .appearance) } }
    public var accent: AccentPalette { didSet { save(accent.rawValue, .accent) } }

    // MARK: Notifications

    public var notificationsEnabled: Bool { didSet { save(notificationsEnabled, .notifications) } }
    public var showMessagePreviews: Bool { didSet { save(showMessagePreviews, .previews) } }
    public var inAppSounds: Bool { didSet { save(inAppSounds, .inAppSounds) } }
    public var inAppVibrate: Bool { didSet { save(inAppVibrate, .inAppVibrate) } }
    public var countMutedChats: Bool { didSet { save(countMutedChats, .countMuted) } }

    // MARK: Privacy

    public var readReceiptsEnabled: Bool { didSet { save(readReceiptsEnabled, .readReceipts) } }
    public var lastSeenVisibility: Visibility { didSet { save(lastSeenVisibility.rawValue, .lastSeen) } }
    public var photoVisibility: Visibility { didSet { save(photoVisibility.rawValue, .photo) } }
    public var passcodeEnabled: Bool { didSet { save(passcodeEnabled, .passcode) } }

    // MARK: Data and storage

    public var photoDownload: AutoDownloadPolicy { didSet { save(photoDownload.rawValue, .photoDownload) } }
    public var videoDownload: AutoDownloadPolicy { didSet { save(videoDownload.rawValue, .videoDownload) } }
    public var fileDownload: AutoDownloadPolicy { didSet { save(fileDownload.rawValue, .fileDownload) } }
    public var saveIncomingToPhotos: Bool { didSet { save(saveIncomingToPhotos, .saveToPhotos) } }

    // MARK: Derived

    /// Initials for the avatar when there is no photo.
    public var initials: String {
        let letters = displayName.split(separator: " ").prefix(2).compactMap(\.first)

        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    /// Placeholder until there is a real media cache to measure.
    public var approximateCacheSize: String {
        Int64(155_600_000).formatted(.byteCount(style: .file))
    }

    // MARK: Storage

    private let defaults: UserDefaults

    private enum Key: String {
        case displayName, username, phoneNumber, bio
        case appearance, accent
        case notifications, previews, inAppSounds, inAppVibrate, countMuted
        case readReceipts, lastSeen, photo, passcode
        case photoDownload, videoDownload, fileDownload, saveToPhotos
    }

    private func save(_ value: Any, _ key: Key) {
        defaults.set(value, forKey: "settings.\(key.rawValue)")
    }

    private func string(_ key: Key) -> String? {
        defaults.string(forKey: "settings.\(key.rawValue)")
    }

    /// `object(forKey:)` rather than `bool(forKey:)` so "never set" is
    /// distinguishable from "set to false".
    private func bool(_ key: Key, default fallback: Bool) -> Bool {
        defaults.object(forKey: "settings.\(key.rawValue)") as? Bool ?? fallback
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        displayName = defaults.string(forKey: "settings.displayName") ?? "Sasha Green"
        username = defaults.string(forKey: "settings.username") ?? "@sasha"
        phoneNumber = defaults.string(forKey: "settings.phoneNumber") ?? "+1 415 555 0117"
        bio = defaults.string(forKey: "settings.bio") ?? "Building interfaces. Mostly lists."

        appearance = AppearanceMode(rawValue: defaults.string(forKey: "settings.appearance") ?? "") ?? .system
        accent = AccentPalette(rawValue: defaults.string(forKey: "settings.accent") ?? "") ?? .blue

        notificationsEnabled = defaults.object(forKey: "settings.notifications") as? Bool ?? true
        showMessagePreviews = defaults.object(forKey: "settings.previews") as? Bool ?? true
        inAppSounds = defaults.object(forKey: "settings.inAppSounds") as? Bool ?? true
        inAppVibrate = defaults.object(forKey: "settings.inAppVibrate") as? Bool ?? true
        countMutedChats = defaults.object(forKey: "settings.countMuted") as? Bool ?? false

        readReceiptsEnabled = defaults.object(forKey: "settings.readReceipts") as? Bool ?? true
        lastSeenVisibility = Visibility(rawValue: defaults.string(forKey: "settings.lastSeen") ?? "") ?? .contacts
        photoVisibility = Visibility(rawValue: defaults.string(forKey: "settings.photo") ?? "") ?? .everybody
        passcodeEnabled = defaults.object(forKey: "settings.passcode") as? Bool ?? false

        photoDownload = AutoDownloadPolicy(rawValue: defaults.string(forKey: "settings.photoDownload") ?? "") ?? .always
        videoDownload = AutoDownloadPolicy(rawValue: defaults.string(forKey: "settings.videoDownload") ?? "") ?? .wifiOnly
        fileDownload = AutoDownloadPolicy(rawValue: defaults.string(forKey: "settings.fileDownload") ?? "") ?? .wifiOnly
        saveIncomingToPhotos = defaults.object(forKey: "settings.saveToPhotos") as? Bool ?? false
    }

    public func reset() {
        displayName = "Sasha Green"
        username = "@sasha"
        phoneNumber = "+1 415 555 0117"
        bio = "Building interfaces. Mostly lists."
        appearance = .system
        accent = .blue
        notificationsEnabled = true
        showMessagePreviews = true
        inAppSounds = true
        inAppVibrate = true
        countMutedChats = false
        readReceiptsEnabled = true
        lastSeenVisibility = .contacts
        photoVisibility = .everybody
        passcodeEnabled = false
        photoDownload = .always
        videoDownload = .wifiOnly
        fileDownload = .wifiOnly
        saveIncomingToPhotos = false
    }
}
