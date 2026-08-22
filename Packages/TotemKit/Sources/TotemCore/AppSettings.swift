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

/// Totem's colourway. Named for what the colour is rather than for its hue,
/// because the hues are ours — see `AccentPalette.color` in TotemUI for the
/// values, which differ between light and dark.
public enum AccentPalette: String, CaseIterable, Identifiable, Sendable {
    case aurora, cobalt, orchid, coral, amber, lagoon

    public var id: String { rawValue }

    public var title: String { rawValue.capitalized }
}

/// Backdrop behind a conversation. A small closed set rather than an image
/// picker, so it costs nothing to ship and still tracks light and dark.
public enum Wallpaper: String, CaseIterable, Identifiable, Sendable {
    case plain, dusk, mint, ember, graphite

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .plain: "None"
        case .dusk: "Dusk"
        case .mint: "Mint"
        case .ember: "Ember"
        case .graphite: "Graphite"
        }
    }
}

/// Message text size. Four steps rather than a free slider, because the values
/// map onto Dynamic Type sizes the system already knows how to lay out.
public enum TextSize: String, CaseIterable, Identifiable, Sendable {
    case small, standard, large, extraLarge

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .small: "Small"
        case .standard: "Default"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }

    /// Position in `allCases`, so a slider can drive the choice.
    public var step: Int { Self.allCases.firstIndex(of: self) ?? 1 }

    public static func at(step: Int) -> TextSize {
        let bounded = min(max(step, 0), allCases.count - 1)

        return allCases[bounded]
    }
}

/// Who can see a given piece of profile information.
///
/// Not `Visibility` — SwiftUI already exports a type by that name, and any
/// file importing both modules would fail to resolve it.
public enum PrivacyAudience: String, CaseIterable, Identifiable, Sendable {
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

/// Languages offered in Settings. A closed list, since nothing is actually
/// localised yet — the picker persists the choice and nothing more.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english, spanish, french, german, portuguese
    case italian, dutch, polish, turkish, japanese, korean, arabic

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .english: "English"
        case .spanish: "Spanish"
        case .french: "French"
        case .german: "German"
        case .portuguese: "Portuguese"
        case .italian: "Italian"
        case .dutch: "Dutch"
        case .polish: "Polish"
        case .turkish: "Turkish"
        case .japanese: "Japanese"
        case .korean: "Korean"
        case .arabic: "Arabic"
        }
    }

    /// Endonym, shown as the subtitle — the way iOS lists languages.
    public var nativeTitle: String {
        switch self {
        case .english: "English"
        case .spanish: "Espanol"
        case .french: "Francais"
        case .german: "Deutsch"
        case .portuguese: "Portugues"
        case .italian: "Italiano"
        case .dutch: "Nederlands"
        case .polish: "Polski"
        case .turkish: "Turkce"
        case .japanese: "Nihongo"
        case .korean: "Hangugeo"
        case .arabic: "Arabiyya"
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
    public var wallpaper: Wallpaper { didSet { save(wallpaper.rawValue, .wallpaper) } }
    public var textSize: TextSize { didSet { save(textSize.rawValue, .textSize) } }

    // MARK: Notifications

    public var notificationsEnabled: Bool { didSet { save(notificationsEnabled, .notifications) } }
    public var showMessagePreviews: Bool { didSet { save(showMessagePreviews, .previews) } }
    public var inAppSounds: Bool { didSet { save(inAppSounds, .inAppSounds) } }
    public var inAppVibrate: Bool { didSet { save(inAppVibrate, .inAppVibrate) } }
    public var countMutedChats: Bool { didSet { save(countMutedChats, .countMuted) } }

    // MARK: Privacy

    public var readReceiptsEnabled: Bool { didSet { save(readReceiptsEnabled, .readReceipts) } }
    public var lastSeenVisibility: PrivacyAudience { didSet { save(lastSeenVisibility.rawValue, .lastSeen) } }
    public var photoVisibility: PrivacyAudience { didSet { save(photoVisibility.rawValue, .photo) } }
    public var groupInviteAudience: PrivacyAudience { didSet { save(groupInviteAudience.rawValue, .groupInvites) } }
    public var passcodeEnabled: Bool { didSet { save(passcodeEnabled, .passcode) } }

    // MARK: Data and storage

    public var photoDownload: AutoDownloadPolicy { didSet { save(photoDownload.rawValue, .photoDownload) } }
    public var videoDownload: AutoDownloadPolicy { didSet { save(videoDownload.rawValue, .videoDownload) } }
    public var fileDownload: AutoDownloadPolicy { didSet { save(fileDownload.rawValue, .fileDownload) } }
    public var saveIncomingToPhotos: Bool { didSet { save(saveIncomingToPhotos, .saveToPhotos) } }

    // MARK: Language

    public var language: AppLanguage { didSet { save(language.rawValue, .language) } }

    // MARK: Derived

    /// Initials for the avatar when there is no photo.
    public var initials: String {
        let letters = displayName.split(separator: " ").prefix(2).compactMap(\.first)

        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    /// Placeholder until there is a real media cache to measure.
    public var approximateCacheSize: String { StorageUsage.totalFormatted }

    // MARK: Storage

    private let defaults: UserDefaults

    private enum Key: String {
        case displayName, username, phoneNumber, bio
        case appearance, accent, wallpaper, textSize
        case notifications, previews, inAppSounds, inAppVibrate, countMuted
        case readReceipts, lastSeen, photo, groupInvites, passcode
        case photoDownload, videoDownload, fileDownload, saveToPhotos
        case language
    }

    private func save(_ value: Any, _ key: Key) {
        defaults.set(value, forKey: "settings.\(key.rawValue)")
    }

    /// `object(forKey:)` rather than `bool(forKey:)` so "never set" stays
    /// distinguishable from "set to false".
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        displayName = defaults.string(forKey: "settings.displayName") ?? "Sasha Green"
        username = defaults.string(forKey: "settings.username") ?? "@sasha"
        phoneNumber = defaults.string(forKey: "settings.phoneNumber") ?? "+1 415 555 0117"
        bio = defaults.string(forKey: "settings.bio") ?? "Building interfaces. Mostly lists."

        appearance = AppearanceMode(rawValue: defaults.string(forKey: "settings.appearance") ?? "") ?? .system
        accent = AccentPalette(rawValue: defaults.string(forKey: "settings.accent") ?? "") ?? .aurora
        wallpaper = Wallpaper(rawValue: defaults.string(forKey: "settings.wallpaper") ?? "") ?? .graphite
        textSize = TextSize(rawValue: defaults.string(forKey: "settings.textSize") ?? "") ?? .standard

        notificationsEnabled = defaults.object(forKey: "settings.notifications") as? Bool ?? true
        showMessagePreviews = defaults.object(forKey: "settings.previews") as? Bool ?? true
        inAppSounds = defaults.object(forKey: "settings.inAppSounds") as? Bool ?? true
        inAppVibrate = defaults.object(forKey: "settings.inAppVibrate") as? Bool ?? true
        countMutedChats = defaults.object(forKey: "settings.countMuted") as? Bool ?? false

        readReceiptsEnabled = defaults.object(forKey: "settings.readReceipts") as? Bool ?? true
        lastSeenVisibility = PrivacyAudience(rawValue: defaults.string(forKey: "settings.lastSeen") ?? "") ?? .contacts
        photoVisibility = PrivacyAudience(rawValue: defaults.string(forKey: "settings.photo") ?? "") ?? .everybody
        groupInviteAudience = PrivacyAudience(rawValue: defaults.string(forKey: "settings.groupInvites") ?? "") ?? .contacts
        passcodeEnabled = defaults.object(forKey: "settings.passcode") as? Bool ?? false

        photoDownload = AutoDownloadPolicy(rawValue: defaults.string(forKey: "settings.photoDownload") ?? "") ?? .always
        videoDownload = AutoDownloadPolicy(rawValue: defaults.string(forKey: "settings.videoDownload") ?? "") ?? .wifiOnly
        fileDownload = AutoDownloadPolicy(rawValue: defaults.string(forKey: "settings.fileDownload") ?? "") ?? .wifiOnly
        saveIncomingToPhotos = defaults.object(forKey: "settings.saveToPhotos") as? Bool ?? false

        language = AppLanguage(rawValue: defaults.string(forKey: "settings.language") ?? "") ?? .english
    }

    public func reset() {
        displayName = "Sasha Green"
        username = "@sasha"
        phoneNumber = "+1 415 555 0117"
        bio = "Building interfaces. Mostly lists."
        appearance = .system
        accent = .aurora
        wallpaper = .graphite
        textSize = .standard
        notificationsEnabled = true
        showMessagePreviews = true
        inAppSounds = true
        inAppVibrate = true
        countMutedChats = false
        readReceiptsEnabled = true
        lastSeenVisibility = .contacts
        photoVisibility = .everybody
        groupInviteAudience = .contacts
        passcodeEnabled = false
        photoDownload = .always
        videoDownload = .wifiOnly
        fileDownload = .wifiOnly
        saveIncomingToPhotos = false
        language = .english
    }
}
