import XCTest

/// Drives the app through its animations while CI records the screen.
///
/// This exists to produce a video, not to assert correctness — a still frame
/// cannot show the tab-bar bubble tracking a finger, a push transition, or the
/// whole app re-tinting when the accent changes. Every step is therefore
/// best-effort: a missing element skips that beat rather than aborting the
/// tour and truncating the clip.
final class DemoTourTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    func testTour() {
        let bar = app.otherElements["tabBar"]

        guard bar.waitForExistence(timeout: 20) else {
            XCTFail("tab bar never appeared — the app may not have launched")
            return
        }

        beat()

        // 1. The signature motion: press the bar and drag across it, so the
        //    bubble follows the finger and each tab lights up in passing.
        dragAcrossBar(bar, from: 0.12, to: 0.88, duration: 1.4)
        beat()
        dragAcrossBar(bar, from: 0.88, to: 0.38, duration: 1.0)
        beat()

        // 2. Discrete taps, to show the bubble springing between positions.
        for slot in [0.125, 0.375, 0.625, 0.875, 0.625] {
            tapBar(bar, at: slot)
            beat(0.9)
        }

        conversationTour(bar)
        settingsTour(bar)

        beat(1.5)
    }

    // MARK: Segments

    /// Push into a conversation, send a message, pop back out.
    private func conversationTour(_ bar: XCUIElement) {
        tapBar(bar, at: 0.625)
        beat()

        let row = app.buttons["chat-c2"]

        guard row.waitForExistence(timeout: 5) else { return }

        row.tap()
        beat(1.4)

        let composer = app.textViews["composer"].exists
            ? app.textViews["composer"]
            : app.textFields["composer"]

        if composer.waitForExistence(timeout: 5) {
            composer.tap()
            composer.typeText("shipping it")
            beat(0.6)

            let send = app.buttons["send"]

            if send.exists {
                send.tap()
                beat(1.2)
            }
        }

        goBack()
    }

    /// Search, a two-level push, and the controls that repaint the whole app.
    private func settingsTour(_ bar: XCUIElement) {
        tapBar(bar, at: 0.875)
        beat()

        searchSettings(for: "storage")

        if openSetting("Data and Storage") {
            beat(1.2)

            let manage = app.buttons["Manage Storage"].firstMatch

            if manage.waitForExistence(timeout: 3) {
                manage.tap()
                beat(1.4)
                goBack()
            }

            goBack()
        }

        if openSetting("Appearance") {
            beat(1.0)

            // Re-tinting: every control, bubble and bar in the app follows.
            tapIfPresent(app.buttons["Purple"].firstMatch)
            beat(0.9)
            tapIfPresent(app.buttons["Mint"].firstMatch)
            beat(0.9)

            let slider = app.sliders.firstMatch

            if slider.exists {
                slider.adjust(toNormalizedSliderPosition: 1.0)
                beat(0.8)
                slider.adjust(toNormalizedSliderPosition: 0.33)
                beat(0.8)
            }

            goBack()
        }

        if openSetting("Privacy and Security") {
            beat(1.0)

            let toggle = app.switches.firstMatch

            if toggle.waitForExistence(timeout: 3) {
                toggle.tap()
                beat(0.8)
                toggle.tap()
                beat(0.8)
            }

            goBack()
        }
    }

    private func searchSettings(for term: String) {
        let field = app.searchFields.firstMatch

        guard field.waitForExistence(timeout: 3) else { return }

        field.tap()
        field.typeText(term)
        beat(1.2)

        tapIfPresent(app.buttons["Cancel"].firstMatch)
        beat(0.8)
    }

    // MARK: Helpers

    /// Rows carry a `settings-` identifier, but fall back to the visible title
    /// so the tour keeps working if one gets renamed.
    @discardableResult
    private func openSetting(_ title: String) -> Bool {
        let byIdentifier = app.buttons["settings-\(title)"].firstMatch

        if byIdentifier.waitForExistence(timeout: 3) {
            byIdentifier.tap()
            return true
        }

        let byLabel = app.buttons[title].firstMatch

        if byLabel.waitForExistence(timeout: 2) {
            byLabel.tap()
            return true
        }

        return false
    }

    private func goBack() {
        let back = app.navigationBars.buttons.element(boundBy: 0)

        if back.exists {
            back.tap()
            beat(1.1)
        }
    }

    private func tapIfPresent(_ element: XCUIElement) {
        if element.exists, element.isHittable {
            element.tap()
        }
    }

    /// A pause long enough for an animation to finish and read on video.
    private func beat(_ seconds: TimeInterval = 1.1) {
        Thread.sleep(forTimeInterval: seconds)
    }

    private func tapBar(_ bar: XCUIElement, at fraction: Double) {
        bar.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.5)).tap()
    }

    /// Slow drag so the video shows the bubble tracking rather than jumping.
    private func dragAcrossBar(
        _ bar: XCUIElement,
        from start: Double,
        to end: Double,
        duration: TimeInterval
    ) {
        let a = bar.coordinate(withNormalizedOffset: CGVector(dx: start, dy: 0.5))
        let b = bar.coordinate(withNormalizedOffset: CGVector(dx: end, dy: 0.5))

        a.press(forDuration: duration, thenDragTo: b)
    }
}
