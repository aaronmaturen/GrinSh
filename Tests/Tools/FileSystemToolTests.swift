import XCTest
@testable import GrinshCore

final class FileSystemToolTests: XCTestCase {
    var tool: FileSystemTool!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        tool = FileSystemTool()

        // Create temporary directory for testing
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        tool = nil

        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }

        try await super.tearDown()
    }

    // MARK: - List Tests

    func testListEmptyDirectory() {
        let result = tool.execute(action: "list:\(tempDir.path)")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "(empty)")
    }

    func testListDirectory() throws {
        // Create test files
        let file1 = tempDir.appendingPathComponent("file1.txt")
        let file2 = tempDir.appendingPathComponent("file2.txt")
        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)

        let result = tool.execute(action: "list:\(tempDir.path)")

        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("file1.txt"))
        XCTAssertTrue(result.output.contains("file2.txt"))
    }

    func testListDirectoryWithSubdirectories() throws {
        let subdir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)

        let result = tool.execute(action: "list:\(tempDir.path)")

        XCTAssertTrue(result.success)
        // Directories should have trailing slash
        XCTAssertTrue(result.output.contains("subdir/"))
    }

    // MARK: - Read/Write Tests

    func testWriteAndReadFile() throws {
        let filePath = tempDir.appendingPathComponent("test.txt").path

        // Write file
        let writeResult = tool.execute(action: "write:\(filePath):Hello, World!")
        XCTAssertTrue(writeResult.success)

        // Read file
        let readResult = tool.execute(action: "read:\(filePath)")
        XCTAssertTrue(readResult.success)
        XCTAssertEqual(readResult.output, "Hello, World!")
    }

    func testReadNonexistentFile() {
        let filePath = tempDir.appendingPathComponent("nonexistent.txt").path

        let result = tool.execute(action: "read:\(filePath)")
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
    }

    // MARK: - Copy Tests

    func testCopyFile() throws {
        let source = tempDir.appendingPathComponent("source.txt")
        let dest = tempDir.appendingPathComponent("dest.txt")

        try "test content".write(to: source, atomically: true, encoding: .utf8)

        let result = tool.execute(action: "copy:\(source.path):\(dest.path)")
        XCTAssertTrue(result.success)

        // Verify dest exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))

        // Verify content is the same
        let content = try String(contentsOf: dest, encoding: .utf8)
        XCTAssertEqual(content, "test content")
    }

    // MARK: - Move Tests

    func testMoveFile() throws {
        let source = tempDir.appendingPathComponent("source.txt")
        let dest = tempDir.appendingPathComponent("dest.txt")

        try "test content".write(to: source, atomically: true, encoding: .utf8)

        let result = tool.execute(action: "move:\(source.path):\(dest.path)")
        XCTAssertTrue(result.success)

        // Verify source doesn't exist
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))

        // Verify dest exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
    }

    // MARK: - Delete Tests

    func testDeleteFile() throws {
        let file = tempDir.appendingPathComponent("delete-me.txt")
        try "content".write(to: file, atomically: true, encoding: .utf8)

        let result = tool.execute(action: "delete:\(file.path)")
        XCTAssertTrue(result.success)

        // Verify file doesn't exist
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    // MARK: - Mkdir Tests

    func testMakeDirectory() {
        let newDir = tempDir.appendingPathComponent("newdir")

        let result = tool.execute(action: "mkdir:\(newDir.path)")
        XCTAssertTrue(result.success)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: newDir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testMakeNestedDirectory() {
        let nestedDir = tempDir.appendingPathComponent("a/b/c")

        let result = tool.execute(action: "mkdir:\(nestedDir.path)")
        XCTAssertTrue(result.success)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedDir.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    // MARK: - Info Tests

    func testGetFileInfo() throws {
        let file = tempDir.appendingPathComponent("info-test.txt")
        try "test content".write(to: file, atomically: true, encoding: .utf8)

        let result = tool.execute(action: "info:\(file.path)")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("File:"))
        XCTAssertTrue(result.output.contains("Size:"))
        XCTAssertTrue(result.output.contains("Modified:"))
    }

    // MARK: - Search Tests

    func testSearchFiles() throws {
        // Create test files
        try "content".write(to: tempDir.appendingPathComponent("test1.txt"), atomically: true, encoding: .utf8)
        try "content".write(to: tempDir.appendingPathComponent("test2.txt"), atomically: true, encoding: .utf8)
        try "content".write(to: tempDir.appendingPathComponent("other.txt"), atomically: true, encoding: .utf8)

        let result = tool.execute(action: "search:\(tempDir.path):test")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.output.contains("test1.txt"))
        XCTAssertTrue(result.output.contains("test2.txt"))
        XCTAssertFalse(result.output.contains("other.txt"))
    }

    func testSearchNoMatches() {
        let result = tool.execute(action: "search:\(tempDir.path):nonexistent")
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "No matches found")
    }

    // MARK: - Error Handling Tests

    func testInvalidAction() {
        let result = tool.execute(action: "invalid")
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
    }

    func testMissingParameters() {
        let result = tool.execute(action: "read")
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.error?.contains("Missing") ?? false)
    }
}
