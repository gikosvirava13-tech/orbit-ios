import Foundation

// MARK: - Peer

/// Anything a conversation can be with. Telegram calls this a Peer, and keeping
/// the same vocabulary means a user, a group and a channel stay interchangeable
/// everywhere above this layer.
public struct Peer: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case user
        case group
        case channel
    }

    public let id: String
    public var name: String
    public var kind: Kind
    public var presence: Presence
    public var isVerified: Bool
    /// Members for a group, subscribers for a channel, `nil` for a user.
    public var memberCount: Int?

    public init(
        id: String,
        name: String,
        kind: Kind,
        presence: Presence = .offline,
        isVerified: Bool = false,
        memberCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.presence = presence
        self.isVerified = isVerified
        self.memberCount = memberCount
    }

    /// Up to two letters, used when there is no avatar image.
    public var initials: String {
        let letters = name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)

        return String(letters).uppercased()
    }

    /// Per-peer index so a peer always gets the same avatar colour.
    ///
    /// Deliberately not `hashValue`: Swift seeds String hashing per process,
    /// so that would repaint every avatar on each launch.
    public var colorIndex: Int {
        id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 1_000_003 }
    }
}

// MARK: - Presence

public enum Presence: Hashable, Sendable {
    case online
    case recently
    case offline

    public var isOnline: Bool { self == .online }
}

// MARK: - Message

public struct Message: Identifiable, Hashable, Sendable {
    public enum Delivery: Hashable, Sendable {
        case sending
        case sent
        case read
    }

    public let id: String
    public var text: String
    public var date: Date
    public var isOutgoing: Bool
    public var delivery: Delivery
    /// Author name, shown only in groups for incoming messages.
    public var authorName: String?
    public var reaction: String?

    public init(
        id: String = UUID().uuidString,
        text: String,
        date: Date,
        isOutgoing: Bool,
        delivery: Delivery = .sent,
        authorName: String? = nil,
        reaction: String? = nil
    ) {
        self.id = id
        self.text = text
        self.date = date
        self.isOutgoing = isOutgoing
        self.delivery = delivery
        self.authorName = authorName
        self.reaction = reaction
    }
}

// MARK: - Chat

public struct Chat: Identifiable, Hashable, Sendable {
    public let id: String
    public var peer: Peer
    public var messages: [Message]
    public var unreadCount: Int
    public var isPinned: Bool
    public var isMuted: Bool
    public var isTyping: Bool

    public init(
        id: String,
        peer: Peer,
        messages: [Message] = [],
        unreadCount: Int = 0,
        isPinned: Bool = false,
        isMuted: Bool = false,
        isTyping: Bool = false
    ) {
        self.id = id
        self.peer = peer
        self.messages = messages
        self.unreadCount = unreadCount
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.isTyping = isTyping
    }

    public var lastMessage: Message? { messages.last }

    /// The preview line in the chat list, prefixed with the author in groups.
    public var previewText: String {
        guard let last = lastMessage else { return "" }
        if let author = last.authorName, !last.isOutgoing, peer.kind != .user {
            return "\(author): \(last.text)"
        }
        return last.text
    }

    public var date: Date { lastMessage?.date ?? .distantPast }

    /// Subtitle under the peer name in a conversation.
    public var statusText: String {
        if isTyping { return "typing…" }
        switch peer.kind {
        case .user:
            switch peer.presence {
            case .online: return "online"
            case .recently: return "last seen recently"
            case .offline: return "last seen a long time ago"
            }
        case .group:
            return "\(peer.memberCount ?? 0) members"
        case .channel:
            let count = peer.memberCount ?? 0
            return "\(count.formatted(.number.notation(.compactName))) subscribers"
        }
    }
}

// MARK: - Chat list sections

public enum ChatListFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case unread = "Unread"
    case groups = "Groups"
    case channels = "Channels"

    public var id: String { rawValue }

    public func matches(_ chat: Chat) -> Bool {
        switch self {
        case .all: return true
        case .unread: return chat.unreadCount > 0
        case .groups: return chat.peer.kind == .group
        case .channels: return chat.peer.kind == .channel
        }
    }
}
