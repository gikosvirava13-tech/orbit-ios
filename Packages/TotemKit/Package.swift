// swift-tools-version: 5.9
import PackageDescription

// telegram-ios splits its code into dozens of small frameworks under
// submodules/ (TelegramCore, Postbox, Display, TelegramUI, …) so that the
// data layer never imports UIKit and features stay independently buildable.
// This mirrors that shape with SPM instead of Bazel:
//
//   TotemCore      ≈ TelegramCore + Postbox   — models and state, no UI
//   TotemUI        ≈ Display                  — design system primitives
//   TotemFeatures  ≈ TelegramUI               — the screens
//
// The dependency arrow only ever points downwards.
let package = Package(
    name: "TotemKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "TotemCore", targets: ["TotemCore"]),
        .library(name: "TotemUI", targets: ["TotemUI"]),
        .library(name: "TotemFeatures", targets: ["TotemFeatures"])
    ],
    targets: [
        .target(name: "TotemCore"),
        .target(name: "TotemUI", dependencies: ["TotemCore"]),
        .target(name: "TotemFeatures", dependencies: ["TotemCore", "TotemUI"]),
        .testTarget(name: "TotemCoreTests", dependencies: ["TotemCore"])
    ]
)
