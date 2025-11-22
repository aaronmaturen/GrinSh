import Foundation

class SpotlightTool: Tool {
    let name = "spotlight"
    let description = "Spotlight search: find files, apps, content"

    func execute(action: String) -> ToolResult {
        let parts = action.components(separatedBy: ":")
        guard let command = parts.first else {
            return .failure("Invalid action format")
        }

        switch command {
        case "search":
            guard parts.count > 1 else { return .failure("Missing search query") }
            let query = parts.dropFirst().joined(separator: ":")
            return search(query: query)
        case "find-file":
            guard parts.count > 1 else { return .failure("Missing filename") }
            return findFile(name: parts[1])
        case "find-app":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return findApp(name: parts[1])
        default:
            return .failure("Unknown command: \(command)")
        }
    }

    private func search(query: String) -> ToolResult {
        let result = runCommand("mdfind '\(query)' 2>/dev/null | head -20")

        if result.exitCode == 0 {
            let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(output.isEmpty ? "No results found" : output)
        } else {
            return .failure("Search failed: \(result.output)")
        }
    }

    private func findFile(name: String) -> ToolResult {
        let result = runCommand("mdfind 'kMDItemFSName == \"\(name)\"' 2>/dev/null | head -20")

        if result.exitCode == 0 {
            let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(output.isEmpty ? "No files found" : output)
        } else {
            return .failure("Search failed: \(result.output)")
        }
    }

    private func findApp(name: String) -> ToolResult {
        let result = runCommand("mdfind 'kMDItemKind == \"Application\" && kMDItemFSName == \"*\(name)*.app\"' 2>/dev/null | head -20")

        if result.exitCode == 0 {
            let output = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
            return .success(output.isEmpty ? "No apps found" : output)
        } else {
            return .failure("Search failed: \(result.output)")
        }
    }
}
