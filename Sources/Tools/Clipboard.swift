import Foundation
import AppKit

class ClipboardTool: Tool {
    let name = "clipboard"
    let description = "Clipboard operations: get, set"

    func execute(action: String) -> ToolResult {
        let parts = action.components(separatedBy: ":")
        guard let command = parts.first else {
            return .failure("Invalid action format")
        }

        switch command {
        case "get":
            return getClipboard()
        case "set":
            guard parts.count > 1 else { return .failure("Missing content") }
            let content = parts.dropFirst().joined(separator: ":")
            return setClipboard(content: content)
        case "clear":
            return clearClipboard()
        default:
            return .failure("Unknown command: \(command)")
        }
    }

    private func getClipboard() -> ToolResult {
        let pasteboard = NSPasteboard.general

        if let content = pasteboard.string(forType: .string) {
            return .success(content)
        } else {
            return .success("(clipboard empty or contains non-text data)")
        }
    }

    private func setClipboard(content: String) -> ToolResult {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let success = pasteboard.setString(content, forType: .string)

        if success {
            return .success("Clipboard set")
        } else {
            return .failure("Could not set clipboard")
        }
    }

    private func clearClipboard() -> ToolResult {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return .success("Clipboard cleared")
    }
}
