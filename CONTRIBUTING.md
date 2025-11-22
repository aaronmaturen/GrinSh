# Contributing to grinsh

Thank you for your interest in contributing to grinsh! This document provides guidelines and instructions for contributing.

---

## Development Setup

### Prerequisites

- macOS 13.0 or later
- Swift 5.9 or later
- Xcode Command Line Tools
- Homebrew (optional, for testing Homebrew integration)
- Claude API key for testing

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/aaronmaturen/GrinSh.git
cd grinsh

# Build the project
swift build

# Run tests
swift test

# Run grinsh in development
.build/debug/grinsh
```

---

## Development Workflow

### 1. Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or a bugfix branch
git checkout -b fix/bug-description
```

### 2. Make Changes

- Write clean, documented code
- Follow Swift naming conventions
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
swift test

# Run specific test
swift test --filter YourTestName

# Run with code coverage
swift test --enable-code-coverage

# Build release to ensure it compiles
swift build -c release
```

### 4. Commit Your Changes

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Add feature: description of what you added"
```

Follow these commit message guidelines:
- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests when applicable

### 5. Push and Create PR

```bash
# Push your branch
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear description of changes
- Screenshots/examples if applicable
- Reference to related issues
- Test results if relevant

**Note:** When creating a PR to `main`, if your VERSION file matches the latest release, the CI will automatically bump it to the next minor version and commit to your PR. You can manually adjust the version type if needed before merging.

---

## Code Style

### Swift Style Guide

- Use 4 spaces for indentation
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### Example

```swift
// Good
func execute(action: String) -> ToolResult {
    guard let command = parseAction(action) else {
        return .failure("Invalid action format")
    }

    return performCommand(command)
}

// Avoid
func doStuff(a: String) -> ToolResult {
    // Complex logic without explanation
    let x = a.split(separator: ":")[0]
    // ...
}
```

---

## Testing Guidelines

### Writing Tests

- Write tests for all new functionality
- Test both success and failure cases
- Use descriptive test names
- Clean up resources in `tearDown()`
- Use temporary directories for file operations

### Test Structure

```swift
import XCTest
@testable import GrinshCore

final class MyFeatureTests: XCTestCase {
    var feature: MyFeature!
    var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        // Setup test fixtures
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        feature = MyFeature()
    }

    override func tearDown() async throws {
        // Clean up
        feature = nil
        if FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }
        try await super.tearDown()
    }

    func testBasicFunctionality() {
        let result = feature.doSomething()
        XCTAssertTrue(result.success)
    }
}
```

---

## Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible new features
- **PATCH** version for backwards-compatible bug fixes

### Creating a Release

#### Option 1: Using the Bump Version Script (Recommended)

The easiest way to create a release:

```bash
# Bump minor version (default) - e.g., 1.0.0 → 1.1.0
./scripts/bump-version.sh

# Bump major version - e.g., 1.0.0 → 2.0.0
./scripts/bump-version.sh major

# Bump patch version - e.g., 1.0.0 → 1.0.1
./scripts/bump-version.sh patch

# Set specific version
./scripts/bump-version.sh 2.5.0
```

The script will:
- Update the VERSION file
- Update CHANGELOG.md (if [Unreleased] section exists)
- Create a git commit
- Optionally create and push a git tag
- Trigger the release workflow automatically

#### Option 2: Using GitHub Actions UI

1. Go to **Actions** → **Bump Version**
2. Click **Run workflow**
3. Select bump type (major/minor/patch)
4. Click **Run workflow**

This will automatically:
- Update VERSION file
- Update CHANGELOG.md
- Create commit and tag
- Push to repository
- Trigger release build

#### Option 3: Manual Release

1. Update VERSION file manually:
   ```bash
   echo "1.2.0" > VERSION
   ```

2. Update CHANGELOG.md (optional but recommended)

3. Commit and tag:
   ```bash
   git add VERSION CHANGELOG.md
   git commit -m "Bump version to 1.2.0"
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin main
   git push origin v1.2.0
   ```

4. The release workflow will automatically build and publish

### Release Checklist

Before creating a release:

- [ ] All tests pass (`swift test`)
- [ ] Update VERSION file
- [ ] Update CHANGELOG.md (if exists)
- [ ] Update README.md if needed
- [ ] Test release build locally (`swift build -c release`)
- [ ] Verify all documentation is up to date
- [ ] Ensure CI/CD passes on main branch

---

## Project Structure

```
grinsh/
├── Sources/              # Main source code
│   ├── main.swift       # Entry point
│   ├── Agent.swift      # Claude API integration
│   ├── Config.swift     # Configuration management
│   ├── Context.swift    # Conversation context
│   ├── Database.swift   # SQLite operations
│   ├── Homebrew.swift   # Homebrew integration
│   └── Tools/           # Tool implementations
├── Tests/               # Test suite
│   ├── ConfigTests.swift
│   ├── DatabaseTests.swift
│   └── ...
├── .github/             # GitHub Actions workflows
│   └── workflows/
│       ├── test.yml     # CI testing
│       ├── release.yml  # Release builds
│       └── auto-release.yml  # Auto-release on merge
└── Package.swift        # Swift package manifest
```

---

## Adding New Tools

To add a new built-in tool:

1. Create the tool file in `Sources/Tools/`:
   ```swift
   import Foundation

   class MyNewTool: Tool {
       let name = "mytool"
       let description = "What this tool does"

       func execute(action: String) -> ToolResult {
           // Implementation
       }
   }
   ```

2. Register it in `Agent.swift`:
   ```swift
   private let myNewTool: MyNewTool

   init(...) {
       self.myNewTool = MyNewTool()
       // ...
   }

   private func executeTool(...) {
       switch name.lowercased() {
       case "mytool":
           result = myNewTool.execute(action: action)
       // ...
       }
   }
   ```

3. Update the system prompt in `Context.swift` to include the new tool

4. Write tests in `Tests/Tools/MyNewToolTests.swift`

---

## Getting Help

- **Questions**: Open a [GitHub Discussion](../../discussions)
- **Bug Reports**: Open an [Issue](../../issues)
- **Security Issues**: Email security@example.com (do not open public issues)
- **Documentation**: Check the [README](README.md) and [Tests/README](Tests/README.md)

---

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what's best for the community
- Show empathy towards others

---

## License

By contributing to grinsh, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to grinsh! 🎉
