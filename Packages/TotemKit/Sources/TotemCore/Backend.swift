import Foundation

// MARK: - Identity

/// A signed-in person, or anyone else's public profile. The distinction is
/// whether `id` matches the session's user, not a different type.
public struct Account: Identifiable, Hashable, Sendable {
    public let id: String
    public var username: String
    public var displayName: String
    public var bio: String
    public var avatarURL: URL?
    public var lastSeen: Date

    public init(
        id: String,
        username: String,
        displayName: String,
        bio: String = "",
        avatarURL: URL? = nil,
        lastSeen: Date = .now
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.lastSeen = lastSeen
    }

    public var handle: String { "@" + username }

    /// Up to two letters, used when there is no avatar image.
    public var initials: String {
        let letters = displayName.split(separator: " ").prefix(2).compactMap(\.first)

        return letters.isEmpty ? "?" : String(letters).uppercased()
    }
}

/// Where you stand with someone. Decided by the server and returned alongside
/// each search result, so a row can render its own button without the client
/// cross-referencing a friends list against a requests list.
public enum Relationship: String, Hashable, Sendable {
    case none
    case requested
    case incoming
    case friends
    case blocked
}

public struct PersonResult: Identifiable, Hashable, Sendable {
    public let account: Account
    public var relationship: Relationship

    public var id: String { account.id }

    public init(account: Account, relationship: Relationship) {
        self.account = account
        self.relationship = relationship
    }
}

public struct FriendRequest: Identifiable, Hashable, Sendable {
    public let id: String
    public let account: Account
    public let date: Date

    public init(id: String, account: Account, date: Date) {
        self.id = id
        self.account = account
        self.date = date
    }
}

// MARK: - Sending

/// A message on its way out.
///
/// `clientID` is generated before the first attempt and reused on every retry.
/// The server has a unique index on it, so a send that times out and gets
/// retried lands once — the single most important detail in a chat client,
/// because the failure it prevents is the one users notice most.
public struct OutgoingMessage: Identifiable, Hashable, Sendable {
    public let clientID: String
    public let conversationID: String
    public let body: String
    public let createdAt: Date

    public var id: String { clientID }

    public init(
        clientID: String = UUID().uuidString,
        conversationID: String,
        body: String,
        createdAt: Date = .now
    ) {
        self.clientID = clientID
        self.conversationID = conversationID
        self.body = body
        self.createdAt = createdAt
    }
}

// MARK: - Events

/// What the realtime connection pushes. Deliberately small: an event says what
/// changed, and the store decides whether it already knows.
public enum BackendEvent: Sendable {
    case messageInserted(conversationID: String, message: Message)
    case messageUpdated(conversationID: String, message: Message)
    case conversationChanged(conversationID: String)
    case readStateChanged(conversationID: String, lastReadSeq: Int64)
    case friendshipChanged
    case presence(userID: String, isOnline: Bool)
    case typing(conversationID: String, userID: String)
}

/// Connection state, surfaced so the UI can say "connecting" honestly instead
/// of showing stale data as though it were live.
public enum BackendStatus: Hashable, Sendable {
    case signedOut
    case connecting
    case online
    case offline(retryingIn: TimeInterval)
}

// MARK: - Errors

public enum BackendError: LocalizedError, Sendable {
    case notConfigured
    case notAuthenticated
    case usernameTaken
    case invalidCredentials
    case rateLimited(retryAfter: TimeInterval)
    case server(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            "This build has no server configured. See supabase/README.md."
        case .notAuthenticated:
            "You are signed out."
        case .usernameTaken:
            "That username is already taken."
        case .invalidCredentials:
            "That email and password do not match."
        case let .rateLimited(retryAfter):
            "Too many attempts. Try again in \(Int(retryAfter)) seconds."
        case let .server(message):
            message
        }
    }
}

// MARK: - The contract

/// Everything the app needs from a server.
///
/// Main-actor isolated on purpose: every caller is a view or the store, the
/// methods are `async` so nothing blocks, and the alternative — an actor whose
/// results all have to hop back — buys nothing for a client this size.
///
/// Two implementations exist. `LocalBackend` keeps everything in memory so the
/// app runs, and CI screenshots, with no server at all. `SupabaseBackend` is
/// the real one.
@MainActor
public protocol TotemBackend: AnyObject {
    var status: BackendStatus { get }
    var currentAccount: Account? { get }

    // Auth
    func restoreSession() async
    func signUp(email: String, password: String, username: String, displayName: String) async throws -> Account
    func signIn(email: String, password: String) async throws -> Account
    func signOut() async throws

    // Profile
    func updateProfile(displayName: String, bio: String) async throws -> Account
    func uploadAvatar(_ data: Data) async throws -> URL
    func touchPresence() async

    // People
    func searchPeople(matching query: String) async throws -> [PersonResult]
    func friends() async throws -> [Account]
    func incomingRequests() async throws -> [FriendRequest]
    func sendFriendRequest(to userID: String) async throws
    func respond(to requestID: String, accept: Bool) async throws
    func block(userID: String) async throws

    // Conversations
    func chats() async throws -> [Chat]
    func openDirectConversation(with userID: String) async throws -> String

    /// One page of history, newest first. `before` is the lowest `seq` already
    /// held; `nil` asks for the newest page.
    func messages(in conversationID: String, before: Int64?, limit: Int) async throws -> [Message]

    func send(_ outgoing: OutgoingMessage) async throws -> Message
    func markRead(conversationID: String, upTo seq: Int64) async throws
    func setMuted(_ muted: Bool, conversationID: String) async throws
    func setPinned(_ pinned: Bool, conversationID: String) async throws

    // Realtime
    func connect() async
    func disconnect() async
    func subscribe(to conversationID: String) async
    func unsubscribe(from conversationID: String) async
    func sendTyping(conversationID: String) async

    /// A single stream for the whole session. One consumer, in the store.
    var events: AsyncStream<BackendEvent> { get }
}

// MARK: - Configuration

/// Server details, read from the bundle so they are a build input rather than
/// a literal in source.
///
/// Only the project reference is stored, not the full URL — an `xcconfig`
/// treats `//` as the start of a comment, so `https://x.supabase.co` silently
/// becomes `https:`. Storing the ref and assembling the URL here avoids the
/// trap entirely.
public struct BackendConfiguration: Sendable {
    public let projectRef: String
    public let anonKey: String

    public var url: URL? {
        URL(string: "https://\(projectRef).supabase.co")
    }

    public init(projectRef: String, anonKey: String) {
        self.projectRef = projectRef
        self.anonKey = anonKey
    }

    /// `nil` when the build has no server configured, which is the normal
    /// state for CI and for a fresh clone.
    public static func fromBundle(_ bundle: Bundle = .main) -> BackendConfiguration? {
        let info = bundle.infoDictionary

        guard
            let ref = (info?["SupabaseProjectRef"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            let key = (info?["SupabaseAnonKey"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !ref.isEmpty,
            !key.isEmpty
        else {
            return nil
        }

        return BackendConfiguration(projectRef: ref, anonKey: key)
    }
}
