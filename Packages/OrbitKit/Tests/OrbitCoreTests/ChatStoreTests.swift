import XCTest

@testable import OrbitCore

@MainActor
final class ChatStoreTests: XCTestCase {
    func testSendingAppendsMessageAndUpdatesPreview() {
        let store = ChatStore()
        let before = store.chat(id: "c1")?.messages.count ?? 0

        store.send(text: "  hello  ", to: "c1")

        let chat = store.chat(id: "c1")

        XCTAssertEqual(chat?.messages.count, before + 1)
        XCTAssertEqual(chat?.lastMessage?.text, "hello", "text should be trimmed")
        XCTAssertEqual(chat?.previewText, "hello", "the list preview reads from the same message")
        XCTAssertEqual(chat?.isTyping, false, "sending clears the typing indicator")
    }

    func testSendingWhitespaceOnlyIsIgnored() {
        let store = ChatStore()
        let before = store.chat(id: "c1")?.messages.count ?? 0

        store.send(text: "   \n ", to: "c1")

        XCTAssertEqual(store.chat(id: "c1")?.messages.count, before)
    }

    func testMutedChatsAreExcludedFromTheBadge() {
        let store = ChatStore()
        let unmutedTotal = store.totalUnreadCount

        store.toggleMuted(chatID: "c1") // c1 carries 3 unread

        XCTAssertEqual(store.totalUnreadCount, unmutedTotal - 3)
    }

    func testMarkReadClearsUnreadCount() {
        let store = ChatStore()

        XCTAssertGreaterThan(store.chat(id: "c1")?.unreadCount ?? 0, 0)
        store.markRead(chatID: "c1")
        XCTAssertEqual(store.chat(id: "c1")?.unreadCount, 0)
    }

    func testPinnedChatsSortAboveNewerOnes() {
        let store = ChatStore()
        let sorted = store.sorted(filter: .all, search: "")

        XCTAssertTrue(sorted.first?.isPinned == true)

        let firstUnpinned = sorted.firstIndex { !$0.isPinned } ?? sorted.count
        let lastPinned = sorted.lastIndex { $0.isPinned } ?? -1

        XCTAssertLessThan(lastPinned, firstUnpinned, "no pinned chat may follow an unpinned one")
    }

    func testSearchMatchesNameAndPreview() {
        let store = ChatStore()

        XCTAssertEqual(store.sorted(filter: .all, search: "nadia").count, 1)
        XCTAssertFalse(store.sorted(filter: .all, search: "icon set").isEmpty)
        XCTAssertTrue(store.sorted(filter: .all, search: "zzzzz").isEmpty)
    }

    func testFiltersSelectByPeerKind() {
        let store = ChatStore()

        XCTAssertTrue(store.sorted(filter: .groups, search: "").allSatisfy { $0.peer.kind == .group })
        XCTAssertTrue(store.sorted(filter: .channels, search: "").allSatisfy { $0.peer.kind == .channel })
        XCTAssertTrue(store.sorted(filter: .unread, search: "").allSatisfy { $0.unreadCount > 0 })
    }

    func testGroupPreviewIsPrefixedWithAuthor() {
        let store = ChatStore()

        XCTAssertEqual(store.chat(id: "c2")?.previewText, "Marcus: shipping the icon set tonight")
    }

    func testMessagesGroupIntoDayBuckets() {
        let messages = PreviewData.chats[0].messages
        let groups = ChatDateFormatter.groupByDay(messages)

        XCTAssertEqual(groups.count, 1, "all of c1 happens on one day")
        XCTAssertEqual(groups.first?.messages.count, messages.count)
    }
}
