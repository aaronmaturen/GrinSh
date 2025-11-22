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
            _ = try database.addMessage(role: "user", content: content)
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
            _ = try database.addMessage(role: "assistant", content: content)
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

        AVAILABLE TOOLS AND THEIR EXACT COMMANDS:

        1. files - File system operations
           Actions: pwd | list:path | read:path | write:path:content | copy:source:dest | move:source:dest | delete:path | trash:path | mkdir:path | info:path | reveal:path | search:directory:pattern

        2. apps - Application management
           Actions: list | launch:app_name | quit:app_name | force-quit:app_name | hide:app_name | unhide:app_name | activate:app_name | frontmost

        3. system - System controls
           Actions: get_volume | set_volume:0.0-1.0 | get_brightness | set_brightness:0.0-1.0 | battery | wifi | disk_space | sleep

        4. clipboard - Clipboard operations
           Actions: get | set:content | clear

        5. spotlight - Spotlight search
           Actions: search:query | find-file:filename | find-app:appname

        6. CLI tools via Homebrew - Any command-line tool (ffmpeg, git, tar, lsof, etc.)
           - Auto-discovered and installed on-demand
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
        User: "where are we?"
        {
            "tool": "files",
            "action": "pwd",
            "explanation": "Getting current working directory"
        }

        User: "list files here"
        {
            "tool": "files",
            "action": "list:.",
            "explanation": "Listing files in current directory"
        }

        User: "copy report.pdf to desktop"
        {
            "tool": "files",
            "action": "copy:report.pdf:~/Desktop/report.pdf",
            "explanation": "Copying report.pdf to Desktop"
        }

        User: "what apps are running?"
        {
            "tool": "apps",
            "action": "list",
            "explanation": "Listing all currently running applications"
        }

        User: "quit slack"
        {
            "tool": "apps",
            "action": "quit:Slack",
            "explanation": "Quitting Slack application"
        }

        User: "turn volume down"
        {
            "tool": "system",
            "action": "set_volume:0.3",
            "explanation": "Setting volume to 30%"
        }

        User: "what's my battery status?"
        {
            "tool": "system",
            "action": "battery",
            "explanation": "Getting battery status"
        }

        User: "find files named report"
        {
            "tool": "spotlight",
            "action": "find-file:report",
            "explanation": "Searching for files named 'report' using Spotlight"
        }

        User: "compress the projects folder"
        {
            "tool": "tar",
            "action": "tar -czf projects.tar.gz projects/",
            "explanation": "Creating compressed archive of projects folder",
            "install_via_brew": "gnu-tar"
        }

        User: "what's using port 8080"
        {
            "tool": "lsof",
            "action": "lsof -i :8080",
            "explanation": "Finding processes using port 8080",
            "install_via_brew": "lsof"
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
