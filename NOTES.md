build

    brew install xcodegen
    xcodegen generate
    open Totem.xcodeproj

set a signing team in project.yml, or in Signing & Capabilities.

layout

    Packages/TotemKit
      TotemCore      models + state, no SwiftUI
      TotemUI        theme, glass, shared controls
      TotemFeatures  the screens
    App/             the entry point
    UITests/         drives the app for the recorded tour

dependencies point downwards only: Features -> UI -> Core.

tests

    Packages/TotemKit/Tests/TotemCoreTests

run without a simulator.

ci

.github/workflows/ios.yml builds on a mac runner, screenshots every screen in
light and dark, records a tour video, and packages an unsigned ipa. artifacts
are on the run page.

the app reads -uiRoute out of UserDefaults and opens straight onto that screen,
which is how the screenshot pass reaches pages two levels deep. keep the list in
the workflow in step with ScreenshotRoute.
