import Foundation

public struct CallRecord: Identifiable, Hashable, Sendable {
    public enum Direction: String, Hashable, Sendable {
        case incoming
        case outgoing
        case missed
    }

    public let id: String
    public var peer: Peer
    public var direction: Direction
    public var date: Date
    /// `nil` for a missed call.
    public var duration: TimeInterval?
    public var isVideo: Bool
    /// Consecutive calls with the same peer collapse into one row, the way the
    /// Phone app and Telegram both do. `nil` means a single call.
    public var repeatCount: Int?

    public init(
        id: String = UUID().uuidString,
        peer: Peer,
        direction: Direction,
        date: Date,
        duration: TimeInterval? = nil,
        isVideo: Bool = false,
        repeatCount: Int? = nil
    ) {
        self.id = id
        self.peer = peer
        self.direction = direction
        self.date = date
        self.duration = duration
        self.isVideo = isVideo
        self.repeatCount = repeatCount
    }

    public var isMissed: Bool { direction == .missed }

    public var title: String {
        guard let repeatCount, repeatCount > 1 else { return peer.name }

        return "\(peer.name) (\(repeatCount))"
    }

    public var subtitle: String {
        switch direction {
        case .missed:
            return "Missed"
        case .incoming, .outgoing:
            let label = direction == .incoming ? "Incoming" : "Outgoing"

            guard let duration else { return label }

            return "\(label) (\(Self.format(duration)))"
        }
    }

    public var symbolName: String {
        if isVideo { return "video.fill" }

        return direction == .outgoing ? "arrow.up.right" : "arrow.down.left"
    }

    private static func format(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())

        if seconds < 60 { return "\(seconds) sec" }

        return "\(seconds / 60) min"
    }
}

public enum CallFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case missed = "Missed"

    public var id: String { rawValue }

    public func matches(_ call: CallRecord) -> Bool {
        self == .all || call.isMissed
    }
}
