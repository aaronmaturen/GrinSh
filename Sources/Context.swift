import Foundation

public struct ConversationMessage: Codable {
    public let role: String
    public let content: String
}

public class Context {
    private let database: Database
    private let config: GrinshConfig
    private var messages: [ConversationMessage] = []

    public init(database: Database, config: GrinshConfig) {
        self.database = database
        self.config = config
        loadMessages()
    }

    private func loadMessages() {
        do {
            let dbMessages = try database.getRecentMessages(limit: config.contextLimit)
            messages = dbMessages.map { msg in
                ConversationMessage(role: msg.role, content: msg.content)
            }
        } catch {
            print("Warning: Could not load message history: \(error)")
            messages = []
        }
    }

    func addUserMessage(_ content: String) {
        let message = ConversationMessage(role: "user", content: content)
        messages.append(message)

        do {
            try database.addMessage(role: "user", content: content)
            try database.addHistory(input: content)
            trimIfNeeded()
        } catch {
            print("Warning: Could not save message: \(error)")
        }
    }

    func addAssistantMessage(_ content: String) {
        let message = ConversationMessage(role: "assistant", content: content)
        messages.append(message)

        do {
            try database.addMessage(role: "assistant", content: content)
            trimIfNeeded()
        } catch {
            print("Warning: Could not save message: \(error)")
        }
    }

    public func getMessages() -> [ConversationMessage] {
        return messages
    }

    public func getMessagesForAPI() -> [[String: String]] {
        return messages.map { ["role": $0.role, "content": $0.content] }
    }

    public func clear() {
        messages = []
        do {
            try database.clearMessages()
        } catch {
            print("Warning: Could not clear messages: \(error)")
        }
    }

    private func trimIfNeeded() {
        while messages.count > config.contextLimit {
            messages.removeFirst()
        }
    }

    public func getSystemPrompt() -> String {
        let learnedTools = getLearnedToolsDescription()

        return """
        You are grinsh, a conversational shell assistant for macOS. Your job is to interpret user requests and execute them using available tools.

        CAPABILITIES:
        1. Built-in tools (native macOS APIs):
           - Files: list, read, write, copy, move, delete, trash, create directory, reveal in Finder
           - Apps: list running apps, launch, quit, force quit, hide, unhide, activate
           - Windows: list, focus, move, resize, minimize, maximize
           - System: get/set volume, get/set brightness, battery status, wifi status, disk space
           - Clipboard: get/set clipboard contents
           - Notifications: send, schedule
           - Spotlight: search files, apps, content
           - Auth: privileged operations via Touch ID/password prompt

        2. CLI tools via Homebrew:
           - Discover and install tools on-demand (ffmpeg, git, tar, lsof, etc.)
           - Learn from tldr pages, --help, man pages
           \(learnedTools)

        RESPONSE FORMAT:
        When a user makes a request, respond in JSON with:
        {
            "tool": "tool_name",
            "action": "specific_command_or_function",
            "explanation": "what you're doing",
            "needs_auth": false
        }

        For CLI tools not yet installed:
        {
            "tool": "ffmpeg",
            "action": "brew install ffmpeg && ffmpeg -i input.mp4 output.gif",
            "explanation": "Installing ffmpeg via Homebrew, then converting video to GIF",
            "needs_auth": false,
            "install_via_brew": "ffmpeg"
        }

        For built-in tools, use the tool name from the list above.
        For privileged operations, set "needs_auth": true

        EXAMPLES:
        User: "compress the projects folder"
        {
            "tool": "tar",
            "action": "tar -czf projects.tar.gz projects/",
            "explanation": "Creating compressed archive of projects folder"
        }

        User: "what's using port 8080"
        {
            "tool": "lsof",
            "action": "lsof -i :8080",
            "explanation": "Finding processes using port 8080"
        }

        User: "turn volume down"
        {
            "tool": "system",
            "action": "set_volume:0.3",
            "explanation": "Setting volume to 30%"
        }

        User: "quit slack"
        {
            "tool": "apps",
            "action": "quit:Slack",
            "explanation": "Quitting Slack application"
        }

        Be concise, practical, and prefer simple solutions. If multiple approaches exist, choose the most straightforward one.
        """
    }

    private func getLearnedToolsDescription() -> String {
        guard let db = try? database.getAllTools(), !db.isEmpty else {
            return ""
        }

        var result = "\n\nLEARNED TOOLS:\n"
        for tool in db {
            result += "   - \(tool.name): \(tool.description)\n"
        }
        return result
    }
}
