import XCTest
@testable import GrinshCore

final class ContextTests: XCTestCase {
    var database: Database!
    var config: GrinshConfig!
    var context: Context!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary database
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let grinshDir = tempDir.appendingPathComponent(".grinsh")
        try FileManager.default.createDirectory(at: grinshDir, withIntermediateDirectories: true)

        database = try Database.createForTesting(at: grinshDir.appendingPathComponent("test.db").path)

        // Create test config
        config = GrinshConfig(apiKey: "test-key", model: "test-model", contextLimit: 5)

        // Create context
        context = Context(database: database, config: config)
    }

    override func tearDown() async throws {
        context = nil
        database = nil

        if FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }

        try await super.tearDown()
    }

    func testAddUserMessage() {
        context.addUserMessage("Hello")

        let messages = context.getMessages()
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, "user")
        XCTAssertEqual(messages[0].content, "Hello")
    }

    func testAddAssistantMessage() {
        context.addAssistantMessage("Hi there")

        let messages = context.getMessages()
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].role, "assistant")
        XCTAssertEqual(messages[0].content, "Hi there")
    }

    func testConversationFlow() {
        context.addUserMessage("What's 2+2?")
        context.addAssistantMessage("4")
        context.addUserMessage("Thanks")
        context.addAssistantMessage("You're welcome")

        let messages = context.getMessages()
        XCTAssertEqual(messages.count, 4)
        XCTAssertEqual(messages[0].role, "user")
        XCTAssertEqual(messages[1].role, "assistant")
        XCTAssertEqual(messages[2].role, "user")
        XCTAssertEqual(messages[3].role, "assistant")
    }

    func testContextLimitTrimming() {
        // Add more messages than the limit (5)
        for i in 1...10 {
            context.addUserMessage("Message \(i)")
        }

        let messages = context.getMessages()
        XCTAssertEqual(messages.count, 5)
        // Should keep the most recent 5
        XCTAssertEqual(messages[0].content, "Message 6")
        XCTAssertEqual(messages[4].content, "Message 10")
    }

    func testGetMessagesForAPI() {
        context.addUserMessage("Hello")
        context.addAssistantMessage("Hi")

        let apiMessages = context.getMessagesForAPI()
        XCTAssertEqual(apiMessages.count, 2)

        XCTAssertEqual(apiMessages[0]["role"], "user")
        XCTAssertEqual(apiMessages[0]["content"], "Hello")
        XCTAssertEqual(apiMessages[1]["role"], "assistant")
        XCTAssertEqual(apiMessages[1]["content"], "Hi")
    }

    func testClearMessages() {
        context.addUserMessage("Message 1")
        context.addUserMessage("Message 2")

        XCTAssertEqual(context.getMessages().count, 2)

        context.clear()

        XCTAssertEqual(context.getMessages().count, 0)
    }

    func testSystemPromptContainsCapabilities() {
        let systemPrompt = context.getSystemPrompt()

        // Check for key capabilities
        XCTAssertTrue(systemPrompt.contains("files"))
        XCTAssertTrue(systemPrompt.contains("apps"))
        XCTAssertTrue(systemPrompt.contains("system"))
        XCTAssertTrue(systemPrompt.contains("clipboard"))
        XCTAssertTrue(systemPrompt.contains("spotlight"))
        XCTAssertTrue(systemPrompt.contains("Homebrew"))
    }

    func testSystemPromptContainsResponseFormat() {
        let systemPrompt = context.getSystemPrompt()

        // Check for JSON response format instructions
        XCTAssertTrue(systemPrompt.contains("tool"))
        XCTAssertTrue(systemPrompt.contains("action"))
        XCTAssertTrue(systemPrompt.contains("explanation"))
    }

    func testPersistenceAcrossContextInstances() throws {
        // Add messages to first context
        context.addUserMessage("First message")
        context.addAssistantMessage("First response")

        // Create new context with same database
        let newContext = Context(database: database, config: config)

        // Should load messages from database
        let messages = newContext.getMessages()
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].content, "First message")
        XCTAssertEqual(messages[1].content, "First response")
    }
}
