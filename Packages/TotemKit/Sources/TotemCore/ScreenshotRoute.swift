import Foundation

/// Lets CI open the app directly on any screen.
///
/// `xcrun simctl launch … -uiRoute appearance` lands in the argument domain of
/// `UserDefaults`, so the app can read it with no extra plumbing. This is far
/// simpler than driving XCUITest just to take pictures, and it means every
/// screen can be captured in light and dark on every push.
public enum ScreenshotRoute: String, CaseIterable, Sendable {
    // Tabs
    case chats
    case conversation
    case newChat
    case calls
    case contacts
    case settings

    // Profile
    case profile
    case editProfile
    case qrCode

    // Settings stack
    case notifications
    case privacy
    case blocked
    case appearance
    case dataStorage
    case storage
    case devices
    case folders
    case saved
    case language
    case help
    case about

    private static let key = "uiRoute"

    public static var current: ScreenshotRoute? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }

        return ScreenshotRoute(rawValue: raw)
    }

    /// Routes that live under the Settings tab, so the root knows which tab to
    /// select before the stack pushes anything.
    public var startsInSettings: Bool {
        switch self {
        case .chats, .conversation, .newChat, .calls, .contacts: false
        default: true
        }
    }

    /// Chat opened when capturing the conversation screen.
    public static let sampleChatID = "c1"
}
