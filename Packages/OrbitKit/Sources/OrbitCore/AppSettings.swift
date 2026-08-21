import Foundation
import Observation

public enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

/// User preferences, persisted to `UserDefaults`. Kept in Core so the data
/// layer can read them too — read receipts, for instance, are a protocol-level
/// concern once a real backend exists, not just a display toggle.
@MainActor
@Observable
public final class AppSettings {
    public var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    public var readReceiptsEnabled: Bool {
        didSet { defaults.set(readReceiptsEnabled, forKey: Key.readReceipts) }
    }

    public var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Key.notifications) }
    }

    public var displayName: String {
        didSet { defaults.set(displayName, forKey: Key.displayName) }
    }

    public var bio: String {
        didSet { defaults.set(bio, forKey: Key.bio) }
    }

    private let defaults: UserDefaults

    private enum Key {
        static let appearance = "settings.appearance"
        static let readReceipts = "settings.readReceipts"
        static let notifications = "settings.notifications"
        static let displayName = "settings.displayName"
        static let bio = "settings.bio"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        appearance = AppearanceMode(rawValue: defaults.string(forKey: Key.appearance) ?? "")
            ?? .system
        // `object(forKey:)` distinguishes "never set" from "set to false".
        readReceiptsEnabled = defaults.object(forKey: Key.readReceipts) as? Bool ?? true
        notificationsEnabled = defaults.object(forKey: Key.notifications) as? Bool ?? true
        displayName = defaults.string(forKey: Key.displayName) ?? "Sasha Green"
        bio = defaults.string(forKey: Key.bio) ?? "Building interfaces. Mostly lists."
    }

    public func reset() {
        appearance = .system
        readReceiptsEnabled = true
        notificationsEnabled = true
        displayName = "Sasha Green"
        bio = "Building interfaces. Mostly lists."
    }
}
