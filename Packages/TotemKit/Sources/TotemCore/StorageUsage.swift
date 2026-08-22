import Foundation

/// One slice of the media cache — a category on the storage screen, or a
/// single conversation on the detail screen.
public struct StorageSlice: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let bytes: Int64

    public init(id: String, title: String, bytes: Int64) {
        self.id = id
        self.title = title
        self.bytes = bytes
    }

    public var formatted: String {
        bytes.formatted(.byteCount(style: .file))
    }
}

/// Fixture numbers for the storage screen.
///
/// Real figures would come from measuring the media cache; keeping them here
/// means the screen is laid out against plausible data instead of zeroes, and
/// the bar has something to divide up.
public enum StorageUsage {
    public static let categories: [StorageSlice] = [
        StorageSlice(id: "photos", title: "Photos", bytes: 62_400_000),
        StorageSlice(id: "videos", title: "Videos", bytes: 54_100_000),
        StorageSlice(id: "files", title: "Files", bytes: 21_800_000),
        StorageSlice(id: "voice", title: "Voice Messages", bytes: 9_300_000),
        StorageSlice(id: "other", title: "Other", bytes: 8_000_000)
    ]

    public static var total: Int64 {
        categories.reduce(0) { $0 + $1.bytes }
    }

    public static var totalFormatted: String {
        total.formatted(.byteCount(style: .file))
    }

    /// Share of the total, for the proportional bar. Guards the divide so an
    /// empty cache renders an empty bar rather than crashing.
    public static func fraction(of slice: StorageSlice) -> Double {
        let total = total

        return total > 0 ? Double(slice.bytes) / Double(total) : 0
    }

    /// Per-conversation usage, derived from message volume so the detail
    /// screen stays consistent with whatever is actually in the store.
    public static func perChat(_ chats: [Chat]) -> [StorageSlice] {
        chats
            .map { chat in
                StorageSlice(
                    id: chat.id,
                    title: chat.peer.name,
                    bytes: Int64(chat.messages.count) * 2_400_000 + 640_000
                )
            }
            .sorted { $0.bytes > $1.bytes }
    }
}
