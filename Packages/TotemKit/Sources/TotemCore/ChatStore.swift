import Foundation
import Observation

/// Single source of truth for conversations, the way Postbox is for
/// telegram-ios: every screen reads from here and nothing keeps its own copy,
/// so sending a message updates the conversation and the chat list together.
///
/// It is `@MainActor` because every mutation is driven by UI events and read
/// back by SwiftUI on the next render; anything genuinely slow (a network
/// round-trip, disk) belongs behind `MessageTransport`, off this actor.
@MainActor
@Observable
public final class ChatStore {
    public private(set) var chats: [Chat]
    public private(set) var calls: [CallRecord]

    private let transport: MessageTransport?

    public init(
        chats: [Chat] = PreviewData.chats,
        calls: [CallRecord] = PreviewData.calls,
        transport: MessageTransport? = nil
    ) {
        self.chats = chats
        self.calls = calls
        self.transport = transport
    }

    // MARK: Calls

    /// `self.calls` throughout: a property and a method share the base name
    /// here, and the bare identifier is ambiguous inside these bodies.
    public func calls(filter: CallFilter) -> [CallRecord] {
        self.calls.filter { filter.matches($0) }.sorted { $0.date > $1.date }
    }

    /// `filter().count` rather than `count(where:)`, which needs the Swift 6
    /// stdlib and so is unavailable on our iOS 17 deployment target.
    public var missedCallCount: Int {
        self.calls.filter(\.isMissed).count
    }

    public func deleteCalls(ids: [String]) {
        guard !ids.isEmpty else { return }
        let doomed = Set(ids)

        self.calls.removeAll { doomed.contains($0.id) }
    }

    // MARK: Reads

    public func chat(id: String) -> Chat? {
        chats.first { $0.id == id }
    }

    /// Pinned first, then newest, matching Telegram's ordering.
    public func sorted(filter: ChatListFilter, search: String) -> [Chat] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return chats
            .filter { filter.matches($0) }
            .filter { chat in
                guard !query.isEmpty else { return true }
                return chat.peer.name.lowercased().contains(query)
                    || chat.previewText.lowercased().contains(query)
            }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
                return lhs.date > rhs.date
            }
    }

    /// Badge total. Muted chats do not contribute, same as Telegram.
    public var totalUnreadCount: Int {
        chats.reduce(0) { $0 + ($1.isMuted ? 0 : $1.unreadCount) }
    }

    // MARK: Writes

    public func send(text: String, to chatID: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = index(of: chatID) else { return }

        let message = Message(
            text: trimmed,
            date: .now,
            isOutgoing: true,
            delivery: transport == nil ? .sent : .sending
        )

        chats[index].messages.append(message)
        chats[index].isTyping = false

        guard let transport else { return }

        Task { [weak self] in
            let delivery = await transport.send(message, in: chatID)
            self?.update(messageID: message.id, in: chatID, delivery: delivery)
        }
    }

    public func markRead(chatID: String) {
        guard let index = index(of: chatID), chats[index].unreadCount != 0 else { return }
        chats[index].unreadCount = 0
    }

    public func togglePinned(chatID: String) {
        guard let index = index(of: chatID) else { return }
        chats[index].isPinned.toggle()
    }

    public func toggleMuted(chatID: String) {
        guard let index = index(of: chatID) else { return }
        chats[index].isMuted.toggle()
    }

    /// Removes conversations by id rather than by index, because the list on
    /// screen is filtered and sorted and its offsets do not match ours.
    public func delete(chatIDs: [String]) {
        guard !chatIDs.isEmpty else { return }
        let doomed = Set(chatIDs)

        chats.removeAll { doomed.contains($0.id) }
    }

    // MARK: Private

    private func index(of chatID: String) -> Int? {
        chats.firstIndex { $0.id == chatID }
    }

    private func update(messageID: String, in chatID: String, delivery: Message.Delivery) {
        guard
            let chatIndex = index(of: chatID),
            let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == messageID })
        else { return }

        chats[chatIndex].messages[messageIndex].delivery = delivery
    }
}

// MARK: - Transport seam

/// The boundary a real backend plugs into. Nothing above TotemCore knows
/// whether messages go to a server or nowhere at all, so the UI can be built
/// and reviewed against `PreviewData` before any backend exists.
public protocol MessageTransport: Sendable {
    func send(_ message: Message, in chatID: String) async -> Message.Delivery
}
