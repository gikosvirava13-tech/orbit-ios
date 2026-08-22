import TotemCore
import TotemUI
import SwiftUI

// MARK: - Data and storage

struct DataStorageSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(ChatStore.self) private var store

    @State private var isClearing = false

    var body: some View {
        @Bindable var settings = settings

        List {
            Section {
                usageCard.plainCardRow()
            }

            Section {
                NavigationLink(value: SettingsDestination.storage) {
                    Label("Manage Storage", systemImage: "slider.horizontal.3")
                }

                Button("Clear Cache", role: .destructive) { isClearing = true }
            } footer: {
                Text("Messages stay. Media is downloaded again the next time you open it.")
            }

            Section {
                policyRow("Photos", symbol: "photo", selection: $settings.photoDownload)
                policyRow("Videos", symbol: "video", selection: $settings.videoDownload)
                policyRow("Files", symbol: "doc", selection: $settings.fileDownload)
            } header: {
                Text("Automatic Download")
            } footer: {
                Text("Anything set to Wi-Fi Only waits until you are off cellular data.")
            }

            Section {
                Toggle("Save Incoming Photos", isOn: $settings.saveIncomingToPhotos)
            } footer: {
                Text("Photos you receive are added to your photo library automatically.")
            }

            Section {
                LabeledContent("Messages Sent", value: sentCount.formatted())
                LabeledContent("Messages Received", value: receivedCount.formatted())
                LabeledContent("Conversations", value: store.chats.count.formatted())
            } header: {
                Text("This Device")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Data and Storage")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear cached media?", isPresented: $isClearing, titleVisibility: .visible) {
            Button("Clear Cache", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This frees \(StorageUsage.totalFormatted). Your messages are not affected.")
        }
    }

    /// Total, a proportional bar, then the legend — the same reading order as
    /// the storage screen in iOS Settings, but as one card rather than a
    /// full-bleed chart.
    private var usageCard: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(StorageUsage.totalFormatted)
                        .font(.title.weight(.semibold))
                        .monospacedDigit()

                    Text("of cached media")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryLabel)

                    Spacer(minLength: 0)
                }

                UsageBar(segments: segments)

                VStack(spacing: 9) {
                    ForEach(legend) { item in
                        UsageLegendRow(color: item.color, title: item.title, detail: item.detail)
                            .font(.subheadline)
                    }
                }
            }
            .padding(16)
        }
    }

    /// Flattened into an `Identifiable` row up front, because `ForEach` over
    /// `enumerated()` would need a key path into a tuple, which Swift has no
    /// way to express.
    private struct LegendItem: Identifiable {
        let id: String
        let title: String
        let detail: String
        let color: Color
    }

    private var legend: [LegendItem] {
        StorageUsage.categories.enumerated().map { index, slice in
            LegendItem(
                id: slice.id,
                title: slice.title,
                detail: slice.formatted,
                color: Theme.usageColor(index)
            )
        }
    }

    private var segments: [UsageBar.Segment] {
        StorageUsage.categories.enumerated().map { index, slice in
            UsageBar.Segment(
                id: slice.id,
                fraction: StorageUsage.fraction(of: slice),
                color: Theme.usageColor(index)
            )
        }
    }

    private var sentCount: Int {
        store.chats.reduce(0) { $0 + $1.messages.filter(\.isOutgoing).count }
    }

    private var receivedCount: Int {
        store.chats.reduce(0) { $0 + $1.messages.filter { !$0.isOutgoing }.count }
    }

    private func policyRow(
        _ title: String,
        symbol: String,
        selection: Binding<AutoDownloadPolicy>
    ) -> some View {
        Picker(selection: selection) {
            ForEach(AutoDownloadPolicy.allCases) { policy in
                Text(policy.title).tag(policy)
            }
        } label: {
            Label(title, systemImage: symbol)
        }
    }
}

// MARK: - Per-conversation storage

/// Which conversations are actually using the space. Sorted heaviest first,
/// with each bar drawn relative to the largest rather than to the total, so
/// the small ones are still visible.
struct StorageDetailView: View {
    @Environment(ChatStore.self) private var store

    @State private var isClearing = false

    var body: some View {
        List {
            Section {
                ForEach(slices) { slice in
                    row(slice)
                }
            } header: {
                Text("By Conversation")
            } footer: {
                Text("Clearing a conversation removes downloaded media only — the messages stay where they are.")
            }

            Section {
                Button("Clear All Media", role: .destructive) { isClearing = true }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Manage Storage")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear media in every chat?", isPresented: $isClearing, titleVisibility: .visible) {
            Button("Clear All Media", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        }
    }

    private var slices: [StorageSlice] {
        StorageUsage.perChat(store.chats)
    }

    private var largest: Int64 {
        slices.first?.bytes ?? 1
    }

    @ViewBuilder
    private func row(_ slice: StorageSlice) -> some View {
        HStack(spacing: 12) {
            if let chat = store.chat(id: slice.id) {
                AvatarView(peer: chat.peer, size: 36, showsPresence: false)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(slice.title)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    Text(slice.formatted)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryLabel)
                        .monospacedDigit()
                }

                UsageBar(
                    segments: [
                        UsageBar.Segment(
                            id: slice.id,
                            fraction: largest > 0 ? Double(slice.bytes) / Double(largest) : 0,
                            color: Color.accentColor
                        )
                    ],
                    height: 5
                )
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("Data and Storage") {
    NavigationStack {
        DataStorageSettingsView()
            .environment(AppSettings())
            .environment(ChatStore())
    }
}

#Preview("Manage Storage") {
    NavigationStack {
        StorageDetailView()
            .environment(ChatStore())
    }
}
