import Foundation

public struct GrinshConfig: Codable {
    public var apiKey: String
    public var model: String
    public var contextLimit: Int

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case model
        case contextLimit = "context_limit"
    }

    static let defaultConfig = GrinshConfig(
        apiKey: "",
        model: "claude-sonnet-4-20250514",
        contextLimit: 50
    )
}

public class Config {
    private static let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".grinshrc")

    public static func load() -> GrinshConfig {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            print("Config file not found at \(configPath.path)")
            print("Please create ~/.grinshrc with your Claude API key.")
            print("\nExample:")
            print("api_key = \"sk-ant-...\"")
            print("model = \"claude-sonnet-4-20250514\"")
            print("context_limit = 50")
            return GrinshConfig.defaultConfig
        }

        do {
            let contents = try String(contentsOf: configPath, encoding: .utf8)
            return try parseTOML(contents)
        } catch {
            print("Error reading config: \(error)")
            return GrinshConfig.defaultConfig
        }
    }

    public static func parseTOMLForTesting(_ content: String) throws -> GrinshConfig {
        return try parseTOML(content)
    }

    private static func parseTOML(_ content: String) throws -> GrinshConfig {
        var config = GrinshConfig.defaultConfig

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse key = value
            let parts = trimmed.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }

            let key = parts[0]
            var value = parts[1]

            // Remove quotes
            if value.hasPrefix("\"") && value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            }

            switch key {
            case "api_key":
                config.apiKey = value
            case "model":
                config.model = value
            case "context_limit":
                if let limit = Int(value) {
                    config.contextLimit = limit
                }
            default:
                break
            }
        }

        return config
    }

    static func save(_ config: GrinshConfig) throws {
        let toml = """
        api_key = "\(config.apiKey)"
        model = "\(config.model)"
        context_limit = \(config.contextLimit)
        """

        try toml.write(to: configPath, atomically: true, encoding: .utf8)
    }
}
