import XCTest
@testable import GrinshCore

// Mock tool for testing
class MockTool: Tool {
    let name = "mock"
    let description = "A mock tool for testing"

    func execute(action: String) -> ToolResult {
        if action == "success" {
            return .success("Mock success")
        } else if action == "failure" {
            return .failure("Mock failure")
        } else {
            return .success("Mock action: \(action)")
        }
    }
}

final class ProtocolTests: XCTestCase {

    func testToolResultSuccess() {
        let result = ToolResult.success("Test output")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "Test output")
        XCTAssertNil(result.error)
    }

    func testToolResultFailure() {
        let result = ToolResult.failure("Test error")

        XCTAssertFalse(result.success)
        XCTAssertEqual(result.output, "")
        XCTAssertEqual(result.error, "Test error")
    }

    func testMockToolSuccess() {
        let tool = MockTool()
        let result = tool.execute(action: "success")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "Mock success")
    }

    func testMockToolFailure() {
        let tool = MockTool()
        let result = tool.execute(action: "failure")

        XCTAssertFalse(result.success)
        XCTAssertEqual(result.error, "Mock failure")
    }

    func testMockToolCustomAction() {
        let tool = MockTool()
        let result = tool.execute(action: "custom")

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.output, "Mock action: custom")
    }

    func testToolNameAndDescription() {
        let tool = MockTool()

        XCTAssertEqual(tool.name, "mock")
        XCTAssertEqual(tool.description, "A mock tool for testing")
    }

    func testRunCommandSuccess() {
        let tool = MockTool()
        let result = tool.runCommand("echo 'Hello'")

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("Hello"))
    }

    func testRunCommandFailure() {
        let tool = MockTool()
        let result = tool.runCommand("false") // 'false' command always returns 1

        XCTAssertNotEqual(result.exitCode, 0)
    }

    func testRunCommandWithOutput() {
        let tool = MockTool()
        let result = tool.runCommand("echo 'test output'")

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("test output"))
    }

    func testRunCommandInvalidCommand() {
        let tool = MockTool()
        let result = tool.runCommand("nonexistent-command-12345")

        XCTAssertNotEqual(result.exitCode, 0)
    }
}
