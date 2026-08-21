# Orbit — iOS

A native SwiftUI messaging app, structured the way `telegram-ios` is: a modular
package graph with the data layer, the design system and the screens in separate
targets, and a generated Xcode project rather than a committed `.pbxproj`.

## Status — read this first

This was written on a Windows machine with **no Swift toolchain and no Xcode**.
That means:

- it has **never been compiled**
- it has **never been run**
- nothing has been visually reviewed

Expect to fix compile errors on the first build. The logic in `OrbitCore` is
covered by tests you can run immediately (`⌘U`) to shake out the data layer
before you look at any UI.

## Build

Requires macOS with Xcode 15 or newer.

```bash
brew install xcodegen   # once
cd orbit-ios
xcodegen generate       # writes Orbit.xcodeproj
open Orbit.xcodeproj
```

Set a signing team in **Signing & Capabilities** (or in `project.yml`), then run.

If you would rather not use XcodeGen: create a new iOS App in Xcode, delete its
`ContentView.swift`, drag `App/OrbitApp.swift` in, then add `Packages/OrbitKit`
via **File ▸ Add Package Dependencies ▸ Add Local**.

## Structure

`telegram-ios` keeps its data layer free of UIKit and splits features into
independently buildable frameworks. Same idea, three targets instead of dozens:

| Target | Telegram equivalent | Contains |
| --- | --- | --- |
| `OrbitCore` | `TelegramCore` + `Postbox` | `Peer`, `Message`, `Chat`, `ChatStore`, `AppSettings`, date formatting. **No SwiftUI import.** |
| `OrbitUI` | `Display` | `Theme`, `AvatarView`, badges, typing indicator. |
| `OrbitFeatures` | `TelegramUI` | Chat list, conversation, contacts, settings. |

Dependencies only point downwards: `Features → UI → Core`.

## Where the design comes from

Every control is a stock SwiftUI component — `TabView`, `NavigationStack`,
`List`, `Form`, `Toggle`, `Picker`, `.searchable`, `.swipeActions`,
`ContentUnavailableView` — and every icon is an SF Symbol. Colours resolve to
system colours (`Color(.label)`, `Color(.separator)`, `Color.accentColor`),
never to a hand-picked hex.

This is deliberate. Built against the iOS 26 SDK, the system draws the tab bar,
navigation bar and `.bar` backgrounds with **Liquid Glass automatically** — the
real implementation, not an imitation. There is no custom glass code here to
drift out of date, and the app inherits Dynamic Type, Increase Contrast, Reduce
Motion and the user's tint colour for free.

Motion is whatever the system does: `NavigationStack` push/pop, sheet
presentation, `List` swipe actions. The only explicit animations are a 0.25s
ease for scroll-to-bottom and a 0.18s ease on the typing dots. Nothing
overshoots.

## Backend

There isn't one. `ChatStore` is seeded from `PreviewData` and everything lives
in memory.

The seam is already cut: implement `MessageTransport` and pass it to
`ChatStore(chats:transport:)`. Sent messages then enter as `.sending` and settle
to `.sent` / `.read` when the transport resolves, without any screen changing.

For real multi-user traffic you still need auth, a persistent store, a realtime
transport, presence and media storage — a separate build from this one.

## Tests

`Packages/OrbitKit/Tests/OrbitCoreTests` covers send/trim behaviour, unread
badge maths with muting, pinned-first ordering, search across name and preview,
filters by peer kind, group preview prefixing, and day bucketing. These run
without a simulator.
