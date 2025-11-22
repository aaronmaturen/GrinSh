import Foundation

class LearnedTool: Tool {
    let name: String
    let description: String
    private let database: Database
    private let homebrew: Homebrew

    init(name: String, description: String, database: Database, homebrew: Homebrew) {
        self.name = name
        self.description = description
        self.database = database
        self.homebrew = homebrew
    }

    func execute(action: String) -> ToolResult {
        // Check if tool is installed
        if !homebrew.isInstalled(package: name) {
            // Try to install via Homebrew
            print("Tool '\(name)' is not installed. Installing via Homebrew...")

            let (success, output) = homebrew.install(package: name)

            if !success {
                return .failure("Could not install \(name): \(output)")
            }

            print(output)
        }

        // Execute the command
        let result = runCommand(action)

        if result.exitCode == 0 {
            return .success(result.output)
        } else {
            return .failure(result.output.isEmpty ? "Command failed" : result.output)
        }
    }

    static func create(name: String, description: String, usage: String, examples: String, database: Database, homebrew: Homebrew) -> LearnedTool {
        // Save to database
        try? database.saveTool(
            name: name,
            description: description,
            usage: usage,
            examples: examples
        )

        return LearnedTool(
            name: name,
            description: description,
            database: database,
            homebrew: homebrew
        )
    }

    static func loadFromDatabase(database: Database, homebrew: Homebrew) -> [LearnedTool] {
        guard let tools = try? database.getAllTools() else {
            return []
        }

        return tools.map { tool in
            LearnedTool(
                name: tool.name,
                description: tool.description,
                database: database,
                homebrew: homebrew
            )
        }
    }
}
