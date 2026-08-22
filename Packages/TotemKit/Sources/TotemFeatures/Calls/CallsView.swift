import TotemCore
import TotemUI
import SwiftUI

public struct CallsView: View {
    @Environment(ChatStore.self) private var store

    @Binding var tab: AppTab

    @State private var filter: CallFilter = .all
    @State private var path: [String] = []
    @State private var isSearching = false
    @State private var search = ""

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

    public var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    Button {
                        // Placeholder for the call composer.
                    } label: {
                        Label("Start New Call", systemImage: "phone.badge.plus")
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Section("Recent Calls") {
                    ForEach(visibleCalls) { call in
                        CallRow(call: call) {
                            store.markRead(chatID: chatID(for: call))
                            path.append(chatID(for: call))
                        }
                    }
                    .onDelete { offsets in
                        store.deleteCalls(ids: offsets.map { visibleCalls[$0].id })
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Calls")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, isPresented: $isSearching, prompt: "Search calls")
            .overlay {
                if visibleCalls.isEmpty {
                    ContentUnavailableView(
                        filter == .missed ? "No Missed Calls" : "No Calls",
                        systemImage: "phone",
                        description: Text("Calls you make and receive appear here.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                // A segmented control in the title position, the way the Phone
                // app puts All / Missed at the top of its list.
                ToolbarItem(placement: .principal) {
                    Picker("Filter", selection: $filter) {
                        ForEach(CallFilter.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $tab) { isSearching = true }
            }
            .navigationDestination(for: String.self) { chatID in
                ConversationView(chatID: chatID)
            }
        }
    }

    private var visibleCalls: [CallRecord] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return store.calls(filter: filter).filter {
            query.isEmpty || $0.peer.name.lowercased().contains(query)
        }
    }

    /// Calls carry a peer, chats carry an id — bridge by peer so tapping a
    /// call opens that person's conversation.
    private func chatID(for call: CallRecord) -> String {
        store.chats.first { $0.peer.id == call.peer.id }?.id ?? call.peer.id
    }
}

struct CallRow: View {
    let call: CallRecord
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: call.symbolName)
                .font(.caption)
                .foregroundStyle(Theme.secondaryLabel)
                .frame(width: 16)

            AvatarView(peer: call.peer, size: 40, showsPresence: false)

            VStack(alignment: .leading, spacing: 1) {
                Text(call.title)
                    .font(.body)
                    .foregroundStyle(call.isMissed ? Theme.destructive : Theme.label)
                    .lineLimit(1)

                Text(call.subtitle)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryLabel)
            }

            Spacer(minLength: 8)

            Text(ChatDateFormatter.listStamp(for: call.date))
                .font(.footnote)
                .foregroundStyle(Theme.secondaryLabel)

            Button(action: onOpen) {
                Image(systemName: "info.circle")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel("Call details")
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    struct Harness: View {
        @State private var tab: AppTab = .calls

        var body: some View {
            CallsView(tab: $tab)
        }
    }

    return Harness()
        .environment(ChatStore())
        .environment(AppSettings())
}
