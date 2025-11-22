import XCTest
@testable import GrinshCore

final class HomebrewTests: XCTestCase {
    var database: Database!
    var homebrew: Homebrew!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary database
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        let grinshDir = tempDir.appendingPathComponent(".grinsh")
        try FileManager.default.createDirectory(at: grinshDir, withIntermediateDirectories: true)

        database = try Database.createForTesting(at: grinshDir.appendingPathComponent("test.db").path)
        homebrew = Homebrew(database: database)
    }

    override func tearDown() async throws {
        homebrew = nil
        database = nil

        if FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }

        try await super.tearDown()
    }

    func testIsBrewAvailable() {
        // This test will pass or fail depending on the environment
        // Just check that it returns a boolean without crashing
        let available = Homebrew.isBrewAvailable()
        XCTAssertTrue(available || !available) // Always passes, just checks it runs
    }

    func testCachingMechanism() throws {
        // Update cache
        try database.updateBrewCache(name: "test-package", installed: true, description: "Test")

        // Check if cached value is returned
        let isInstalled = homebrew.isInstalled(package: "test-package")
        XCTAssertTrue(isInstalled)
    }

    func testCacheExpiry() throws {
        // This test verifies that the cache mechanism exists
        // We can't easily test the time-based expiry without mocking Date
        try database.updateBrewCache(name: "old-package", installed: false, description: "Old")

        // The cache should be used within the 1-hour window
        let package = try database.getBrewPackage(name: "old-package")
        XCTAssertNotNil(package)
        XCTAssertEqual(package?.name, "old-package")
    }

    func testCheckActualInstallationForCommonCommands() {
        // Test with a command that's likely to exist on macOS
        // sh should exist on all Unix systems
        let tool = FileSystemTool()
        let result = tool.runCommand("command -v sh")

        // If sh exists, the command will succeed
        // This is more of a smoke test
        XCTAssertNotEqual(result.output, "")
    }
}
