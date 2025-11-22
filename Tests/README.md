# grinsh Test Suite

This directory contains the comprehensive test suite for grinsh.

## Running Tests

```bash
# Run all tests
swift test

# Run tests in parallel
swift test --parallel

# Run specific test file
swift test --filter ConfigTests

# Run with code coverage
swift test --enable-code-coverage

# Verbose output
swift test -v
```

## Test Structure

### Core Tests

- **ConfigTests.swift** - Configuration file parsing and validation
- **DatabaseTests.swift** - SQLite database operations and persistence
- **ContextTests.swift** - Conversation history management and context limits
- **HomebrewTests.swift** - Homebrew integration and caching

### Tool Tests

- **Tools/ProtocolTests.swift** - Tool protocol and base functionality
- **Tools/FileSystemToolTests.swift** - File system operations

## Test Coverage

The test suite covers:

✅ Configuration parsing (TOML format)
✅ Database operations (messages, tools, brew cache, preferences, history)
✅ Context management and message trimming
✅ File system operations (read, write, copy, move, delete, search)
✅ Tool protocol and error handling
✅ Homebrew caching mechanism

## Writing New Tests

When adding new functionality:

1. Create a test file in the appropriate directory
2. Follow the naming convention: `[Component]Tests.swift`
3. Use `XCTest` framework
4. Set up and tear down test fixtures properly
5. Test both success and failure cases
6. Test edge cases and error handling

Example:

```swift
import XCTest
@testable import GrinshCore

final class MyComponentTests: XCTestCase {
    var component: MyComponent!

    override func setUp() async throws {
        try await super.setUp()
        component = MyComponent()
    }

    override func tearDown() async throws {
        component = nil
        try await super.tearDown()
    }

    func testBasicFunctionality() {
        // Test implementation
        XCTAssertTrue(component.someMethod())
    }
}
```

## CI/CD

Tests are automatically run on:

- Push to `main`, `develop`, or `claude/*` branches
- Pull requests to `main` or `develop`
- Uses GitHub Actions with macOS runners
- Generates code coverage reports

See `.github/workflows/test.yml` for CI configuration.

## Test Database

Tests use isolated temporary databases that are:

- Created in a unique temporary directory for each test run
- Automatically cleaned up after tests complete
- Independent from the user's actual `~/.grinsh/grinsh.db`

## Mocking and Test Helpers

The codebase includes testing helpers:

- `Config.parseTOMLForTesting()` - Parse TOML without file I/O
- `Database.createForTesting(at:)` - Create database at custom path
- `MockTool` - Example tool implementation for testing

## Running Tests in Xcode

1. Open Package.swift in Xcode
2. Select the test target
3. Press `Cmd+U` to run all tests
4. Use the Test Navigator to run individual tests

## Troubleshooting

**Tests failing with "No such file or directory":**
- Ensure test fixtures are properly created in `setUp()`
- Check file paths are using `tempDir` for temporary files

**Database errors:**
- Make sure each test uses a unique temporary directory
- Verify `tearDown()` properly cleans up resources

**Async/await errors:**
- Use `async throws` in `setUp()` and `tearDown()`
- Call `try await super.setUp()` and `try await super.tearDown()`
