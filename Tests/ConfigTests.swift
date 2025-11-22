import XCTest
@testable import GrinshCore

final class ConfigTests: XCTestCase {

    func testDefaultConfig() {
        let config = GrinshConfig.defaultConfig

        XCTAssertEqual(config.apiKey, "")
        XCTAssertEqual(config.model, "claude-sonnet-4-20250514")
        XCTAssertEqual(config.contextLimit, 50)
    }

    func testParseTOMLBasic() throws {
        let toml = """
        api_key = "sk-ant-test123"
        model = "claude-opus-4"
        context_limit = 100
        """

        let config = try Config.parseTOMLForTesting(toml)

        XCTAssertEqual(config.apiKey, "sk-ant-test123")
        XCTAssertEqual(config.model, "claude-opus-4")
        XCTAssertEqual(config.contextLimit, 100)
    }

    func testParseTOMLWithComments() throws {
        let toml = """
        # This is a comment
        api_key = "sk-ant-test456"
        # Another comment
        model = "claude-sonnet-4-20250514"
        context_limit = 25
        """

        let config = try Config.parseTOMLForTesting(toml)

        XCTAssertEqual(config.apiKey, "sk-ant-test456")
        XCTAssertEqual(config.model, "claude-sonnet-4-20250514")
        XCTAssertEqual(config.contextLimit, 25)
    }

    func testParseTOMLWithEmptyLines() throws {
        let toml = """

        api_key = "sk-ant-test789"

        model = "claude-opus-4"

        context_limit = 30

        """

        let config = try Config.parseTOMLForTesting(toml)

        XCTAssertEqual(config.apiKey, "sk-ant-test789")
        XCTAssertEqual(config.model, "claude-opus-4")
        XCTAssertEqual(config.contextLimit, 30)
    }

    func testParseTOMLPartial() throws {
        let toml = """
        api_key = "sk-ant-partial"
        """

        let config = try Config.parseTOMLForTesting(toml)

        XCTAssertEqual(config.apiKey, "sk-ant-partial")
        // Should have defaults for missing values
        XCTAssertEqual(config.model, "claude-sonnet-4-20250514")
        XCTAssertEqual(config.contextLimit, 50)
    }

    func testParseTOMLWithQuotes() throws {
        let toml = """
        api_key = "sk-ant-with-quotes"
        model = "claude-model"
        """

        let config = try Config.parseTOMLForTesting(toml)

        XCTAssertEqual(config.apiKey, "sk-ant-with-quotes")
        XCTAssertEqual(config.model, "claude-model")
    }

    func testParseTOMLInvalidContextLimit() throws {
        let toml = """
        api_key = "sk-ant-test"
        context_limit = not-a-number
        """

        let config = try Config.parseTOMLForTesting(toml)

        // Should keep default for invalid number
        XCTAssertEqual(config.contextLimit, 50)
    }
}
