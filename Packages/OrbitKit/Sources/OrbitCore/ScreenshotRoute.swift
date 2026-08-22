import Foundation

/// Lets CI open the app directly on any screen.
///
/// `xcrun simctl launch … -uiRoute settings` lands in the argument domain of
/// `UserDefaults`, so the app can read it with no extra plumbing. This is far
/// simpler than driving XCUITest just to take pictures, and it means every
/// screen can be captured in light and dark on every push.
public enum ScreenshotRoute: String, CaseIterable, Sendable {
    case chats
    case conversation
    case calls
    case contacts
    case settings
    case profile
    case newChat

    private static let key = "uiRoute"

    public static var current: ScreenshotRoute? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }

        return ScreenshotRoute(rawValue: raw)
    }

    /// Chat opened when capturing the conversation screen.
    public static let sampleChatID = "c1"
}
