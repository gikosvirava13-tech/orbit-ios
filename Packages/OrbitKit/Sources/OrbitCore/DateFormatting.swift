import Foundation

public enum ChatDateFormatter {
    /// Chat-list stamp: time today, weekday this week, otherwise a short date.
    public static func listStamp(for date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current

        if calendar.isDate(date, inSameDayAs: now) {
            return date.formatted(date: .omitted, time: .shortened)
        }

        if let weekAgo = calendar.date(byAdding: .day, value: -6, to: now), date > weekAgo {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }

        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    /// Time inside a message bubble.
    public static func bubbleStamp(for date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// Section header between days in a conversation.
    public static func daySeparator(for date: Date, relativeTo now: Date = .now) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }

        if let weekAgo = calendar.date(byAdding: .day, value: -6, to: now), date > weekAgo {
            return date.formatted(.dateTime.weekday(.wide))
        }

        return date.formatted(.dateTime.day().month(.wide))
    }

    /// Groups a conversation into day buckets, oldest first.
    ///
    /// Returns a named type rather than tuples because `ForEach` needs a
    /// stable `Identifiable`, and Swift has no key paths into tuple elements.
    public static func groupByDay(_ messages: [Message]) -> [MessageDayGroup] {
        let calendar = Calendar.current
        var buckets: [MessageDayGroup] = []

        for message in messages.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: message.date)

            if let last = buckets.indices.last, buckets[last].date == day {
                buckets[last].messages.append(message)
            } else {
                buckets.append(MessageDayGroup(date: day, messages: [message]))
            }
        }

        return buckets
    }
}

/// One day's worth of messages in a conversation.
public struct MessageDayGroup: Identifiable, Hashable, Sendable {
    public let date: Date
    public var messages: [Message]

    public var id: Date { date }

    public init(date: Date, messages: [Message]) {
        self.date = date
        self.messages = messages
    }
}
