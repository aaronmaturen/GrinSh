import XCTest
@testable import GrinshCore

final class DatabaseTests: XCTestCase {
    var database: Database!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create a temporary directory for test database
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Override home directory for testing
        let grinshDir = tempDir.appendingPathComponent(".grinsh")
        try FileManager.default.createDirectory(at: grinshDir, withIntermediateDirectories: true)

        database = try Database.createForTesting(at: grinshDir.appendingPathComponent("test.db").path)
    }

    override func tearDown() async throws {
        database = nil

        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }

        try await super.tearDown()
    }

    // MARK: - Message Tests

    func testAddMessage() throws {
        let messageId = try database.addMessage(role: "user", content: "Hello")
        XCTAssertGreaterThan(messageId, 0)
    }

    func testGetRecentMessages() throws {
        // Add multiple messages
        try database.addMessage(role: "user", content: "Message 1")
        try database.addMessage(role: "assistant", content: "Response 1")
        try database.addMessage(role: "user", content: "Message 2")
        try database.addMessage(role: "assistant", content: "Response 2")

        let messages = try database.getRecentMessages(limit: 3)

        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].content, "Response 1")
        XCTAssertEqual(messages[1].content, "Message 2")
        XCTAssertEqual(messages[2].content, "Response 2")
    }

    func testClearMessages() throws {
        try database.addMessage(role: "user", content: "Message 1")
        try database.addMessage(role: "assistant", content: "Response 1")

        try database.clearMessages()

        let messages = try database.getRecentMessages(limit: 10)
        XCTAssertEqual(messages.count, 0)
    }

    // MARK: - Tool Tests

    func testSaveTool() throws {
        try database.saveTool(
            name: "ffmpeg",
            description: "Video conversion tool",
            usage: "ffmpeg -i input.mp4 output.gif",
            examples: "Convert MP4 to GIF"
        )

        let tool = try database.getTool(name: "ffmpeg")
        XCTAssertNotNil(tool)
        XCTAssertEqual(tool?.name, "ffmpeg")
        XCTAssertEqual(tool?.description, "Video conversion tool")
    }

    func testGetNonexistentTool() throws {
        let tool = try database.getTool(name: "nonexistent")
        XCTAssertNil(tool)
    }

    func testGetAllTools() throws {
        try database.saveTool(name: "ffmpeg", description: "Video tool", usage: "", examples: "")
        try database.saveTool(name: "git", description: "Version control", usage: "", examples: "")

        let tools = try database.getAllTools()
        XCTAssertEqual(tools.count, 2)

        let names = tools.map { $0.name }.sorted()
        XCTAssertEqual(names, ["ffmpeg", "git"])
    }

    // MARK: - Brew Cache Tests

    func testUpdateBrewCache() throws {
        try database.updateBrewCache(
            name: "ffmpeg",
            installed: true,
            description: "Video processing tool"
        )

        let package = try database.getBrewPackage(name: "ffmpeg")
        XCTAssertNotNil(package)
        XCTAssertEqual(package?.name, "ffmpeg")
        XCTAssertTrue(package?.installed ?? false)
    }

    func testIsBrewPackageInstalled() throws {
        try database.updateBrewCache(name: "ffmpeg", installed: true, description: "")
        try database.updateBrewCache(name: "wget", installed: false, description: "")

        XCTAssertTrue(try database.isBrewPackageInstalled(name: "ffmpeg"))
        XCTAssertFalse(try database.isBrewPackageInstalled(name: "wget"))
        XCTAssertFalse(try database.isBrewPackageInstalled(name: "nonexistent"))
    }

    // MARK: - Preference Tests

    func testSetAndGetPreference() throws {
        try database.setPreference(key: "theme", value: "dark")

        let value = try database.getPreference(key: "theme")
        XCTAssertEqual(value, "dark")
    }

    func testGetNonexistentPreference() throws {
        let value = try database.getPreference(key: "nonexistent")
        XCTAssertNil(value)
    }

    func testUpdatePreference() throws {
        try database.setPreference(key: "theme", value: "dark")
        try database.setPreference(key: "theme", value: "light")

        let value = try database.getPreference(key: "theme")
        XCTAssertEqual(value, "light")
    }

    // MARK: - History Tests

    func testAddHistory() throws {
        try database.addHistory(input: "compress folder")
        try database.addHistory(input: "list files")

        let history = try database.getHistory(limit: 10)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].input, "compress folder")
        XCTAssertEqual(history[1].input, "list files")
    }

    func testGetHistoryWithLimit() throws {
        for i in 1...10 {
            try database.addHistory(input: "command \(i)")
        }

        let history = try database.getHistory(limit: 5)
        XCTAssertEqual(history.count, 5)
        // Should get the most recent 5, in chronological order
        XCTAssertEqual(history[0].input, "command 6")
        XCTAssertEqual(history[4].input, "command 10")
    }
}
