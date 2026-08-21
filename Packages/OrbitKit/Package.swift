// swift-tools-version: 5.9
import PackageDescription

// telegram-ios splits its code into dozens of small frameworks under
// submodules/ (TelegramCore, Postbox, Display, TelegramUI, …) so that the
// data layer never imports UIKit and features stay independently buildable.
// This mirrors that shape with SPM instead of Bazel:
//
//   OrbitCore      ≈ TelegramCore + Postbox   — models and state, no UI
//   OrbitUI        ≈ Display                  — design system primitives
//   OrbitFeatures  ≈ TelegramUI               — the screens
//
// The dependency arrow only ever points downwards.
let package = Package(
    name: "OrbitKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OrbitCore", targets: ["OrbitCore"]),
        .library(name: "OrbitUI", targets: ["OrbitUI"]),
        .library(name: "OrbitFeatures", targets: ["OrbitFeatures"])
    ],
    targets: [
        .target(name: "OrbitCore"),
        .target(name: "OrbitUI", dependencies: ["OrbitCore"]),
        .target(name: "OrbitFeatures", dependencies: ["OrbitCore", "OrbitUI"]),
        .testTarget(name: "OrbitCoreTests", dependencies: ["OrbitCore"])
    ]
)
