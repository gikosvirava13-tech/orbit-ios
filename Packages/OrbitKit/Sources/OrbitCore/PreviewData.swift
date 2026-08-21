import Foundation

/// Fixture data for previews and for running the app before a backend exists.
public enum PreviewData {
    private static func at(_ hour: Int, _ minute: Int, daysAgo: Int = 0) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: start) ?? start

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    public static let me = Peer(id: "me", name: "Sasha Green", kind: .user, presence: .online)

    public static let chats: [Chat] = [
        Chat(
            id: "c1",
            peer: Peer(id: "p1", name: "Nadia Rahman", kind: .user, presence: .online),
            messages: [
                Message(
                    id: "m1",
                    text: "did you see the new drop from studio kite?",
                    date: at(19, 31),
                    isOutgoing: false
                ),
                Message(
                    id: "m2",
                    text: "not yet, send it over",
                    date: at(19, 33),
                    isOutgoing: true,
                    delivery: .read
                ),
                Message(
                    id: "m3",
                    text: "posting it in the design channel in a sec. the type work is unreal",
                    date: at(19, 35),
                    isOutgoing: false,
                    reaction: "🔥"
                ),
                Message(
                    id: "m4",
                    text: "ok but the second one is so much better",
                    date: at(19, 42),
                    isOutgoing: false
                )
            ],
            unreadCount: 3,
            isPinned: true,
            isTyping: true
        ),
        Chat(
            id: "c2",
            peer: Peer(
                id: "p2",
                name: "Orbit Design",
                kind: .group,
                presence: .online,
                memberCount: 48
            ),
            messages: [
                Message(
                    id: "m1",
                    text: "final pass on the tab bar icons is in figma",
                    date: at(18, 58),
                    isOutgoing: false,
                    authorName: "Priya"
                ),
                Message(
                    id: "m2",
                    text: "the 24pt grid finally lines up",
                    date: at(19, 4),
                    isOutgoing: false,
                    authorName: "Marcus"
                ),
                Message(
                    id: "m3",
                    text: "beautiful. merging it",
                    date: at(19, 9),
                    isOutgoing: true,
                    delivery: .read
                ),
                Message(
                    id: "m4",
                    text: "shipping the icon set tonight",
                    date: at(19, 12),
                    isOutgoing: false,
                    authorName: "Marcus",
                    reaction: "🎉"
                )
            ],
            unreadCount: 12,
            isPinned: true
        ),
        Chat(
            id: "c3",
            peer: Peer(
                id: "p3",
                name: "Signal Notes",
                kind: .channel,
                isVerified: true,
                memberCount: 12_400
            ),
            messages: [
                Message(
                    id: "m1",
                    text: "Weekly digest — seven links on interface density",
                    date: at(18, 4),
                    isOutgoing: false,
                    reaction: "👏"
                )
            ],
            unreadCount: 1
        ),
        Chat(
            id: "c4",
            peer: Peer(id: "p4", name: "Marcus Bell", kind: .user, presence: .online),
            messages: [
                Message(id: "m1", text: "standup ran long, sorry", date: at(17, 20), isOutgoing: false),
                Message(
                    id: "m2",
                    text: "all good — anything I need to know?",
                    date: at(17, 24),
                    isOutgoing: true,
                    delivery: .read
                ),
                Message(id: "m3", text: "sent you the recording", date: at(17, 26), isOutgoing: false)
            ]
        ),
        Chat(
            id: "c5",
            peer: Peer(
                id: "p5",
                name: "Weekend Climb",
                kind: .group,
                presence: .recently,
                memberCount: 9
            ),
            messages: [
                Message(id: "m1", text: "who's driving?", date: at(15, 47), isOutgoing: false, authorName: "Ilya"),
                Message(id: "m2", text: "I can take four", date: at(15, 52), isOutgoing: true, delivery: .read),
                Message(
                    id: "m3",
                    text: "forecast says clear until sunday",
                    date: at(16, 11),
                    isOutgoing: false,
                    authorName: "Ilya"
                )
            ],
            isMuted: true
        ),
        Chat(
            id: "c6",
            peer: Peer(id: "p6", name: "Ren Tanaka", kind: .user, presence: .recently),
            messages: [
                Message(id: "m1", text: "landed, finally", date: at(14, 30), isOutgoing: false),
                Message(id: "m2", text: "welcome back", date: at(14, 35), isOutgoing: true, delivery: .read)
            ]
        ),
        Chat(
            id: "c7",
            peer: Peer(id: "p7", name: "Product Standup", kind: .group, memberCount: 22),
            messages: [
                Message(
                    id: "m1",
                    text: "notes are in the doc",
                    date: at(11, 5, daysAgo: 3),
                    isOutgoing: false,
                    authorName: "Priya"
                )
            ]
        ),
        Chat(
            id: "c8",
            peer: Peer(id: "p8", name: "Ilya Volkov", kind: .user),
            messages: [
                Message(
                    id: "m1",
                    text: "the API contract changed again",
                    date: at(9, 40, daysAgo: 3),
                    isOutgoing: false
                ),
                Message(
                    id: "m2",
                    text: "let's sync monday",
                    date: at(9, 44, daysAgo: 3),
                    isOutgoing: true,
                    delivery: .read
                )
            ]
        ),
        Chat(
            id: "c9",
            peer: Peer(
                id: "p9",
                name: "Field Notes",
                kind: .channel,
                isVerified: true,
                memberCount: 3_820
            ),
            messages: [
                Message(
                    id: "m1",
                    text: "Issue 31 — what makes a list feel fast",
                    date: at(20, 15, daysAgo: 4),
                    isOutgoing: false
                )
            ],
            isMuted: true
        )
    ]
}
