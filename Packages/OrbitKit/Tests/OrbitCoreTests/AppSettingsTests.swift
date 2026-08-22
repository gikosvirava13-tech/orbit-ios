import XCTest

@testable import OrbitCore

@MainActor
final class AppSettingsTests: XCTestCase {
    /// A throwaway suite per test, so these never touch the real app defaults.
    private func makeDefaults(_ name: String = UUID().uuidString) -> UserDefaults {
        UserDefaults(suiteName: name)!
    }

    func testDefaultsAreSaneOnFirstLaunch() {
        let settings = AppSettings(defaults: makeDefaults())

        XCTAssertEqual(settings.appearance, .system)
        XCTAssertEqual(settings.accent, .blue)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.readReceiptsEnabled)
        XCTAssertEqual(settings.lastSeenVisibility, .contacts)
        XCTAssertEqual(settings.videoDownload, .wifiOnly)
        XCTAssertFalse(settings.countMutedChats)
    }

    func testValuesPersistAcrossInstances() {
        let defaults = makeDefaults()
        let first = AppSettings(defaults: defaults)

        first.displayName = "Ada Lovelace"
        first.accent = .purple
        first.readReceiptsEnabled = false
        first.lastSeenVisibility = .nobody

        let second = AppSettings(defaults: defaults)

        XCTAssertEqual(second.displayName, "Ada Lovelace")
        XCTAssertEqual(second.accent, .purple)
        XCTAssertFalse(second.readReceiptsEnabled)
        XCTAssertEqual(second.lastSeenVisibility, .nobody)
    }

    /// A toggle switched off must survive a relaunch. Reading with
    /// `bool(forKey:)` would silently turn it back on, since a missing key and
    /// a stored `false` are indistinguishable that way.
    func testFalseIsDistinguishedFromUnset() {
        let defaults = makeDefaults()
        let first = AppSettings(defaults: defaults)

        first.notificationsEnabled = false

        XCTAssertFalse(AppSettings(defaults: defaults).notificationsEnabled)
    }

    func testResetRestoresDefaults() {
        let settings = AppSettings(defaults: makeDefaults())

        settings.displayName = "Someone Else"
        settings.accent = .pink
        settings.passcodeEnabled = true
        settings.reset()

        XCTAssertEqual(settings.displayName, "Sasha Green")
        XCTAssertEqual(settings.accent, .blue)
        XCTAssertFalse(settings.passcodeEnabled)
    }

    func testInitialsComeFromTheDisplayName() {
        let settings = AppSettings(defaults: makeDefaults())

        settings.displayName = "Nadia Rahman"
        XCTAssertEqual(settings.initials, "NR")

        settings.displayName = "Prince"
        XCTAssertEqual(settings.initials, "P")
    }
}

@MainActor
final class PeerColorTests: XCTestCase {
    /// A negative index would crash the palette lookup, not just pick an
    /// unexpected colour.
    func testColorIndexIsNeverNegative() {
        for id in ["a", "peer-1", "", "🙂", String(repeating: "z", count: 400)] {
            let peer = Peer(id: id, name: "Test", kind: .user)

            XCTAssertGreaterThanOrEqual(peer.colorIndex, 0, "id: \(id)")
        }
    }

    func testColorIndexIsStableForTheSameID() {
        let a = Peer(id: "p1", name: "One", kind: .user)
        let b = Peer(id: "p1", name: "Different Name", kind: .group)

        XCTAssertEqual(a.colorIndex, b.colorIndex)
    }
}
