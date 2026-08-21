import OrbitCore
import OrbitFeatures
import SwiftUI

@main
struct OrbitApp: App {
    /// Owned here and injected once, so every screen reads the same state —
    /// the role `AccountContext` plays in telegram-ios.
    @State private var store = ChatStore()
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(settings)
        }
    }
}
