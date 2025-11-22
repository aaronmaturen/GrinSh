import Foundation

public struct Color {
    public static let reset = "\u{001B}[0m"
    public static let bold = "\u{001B}[1m"
    public static let dim = "\u{001B}[2m"

    public static let green = "\u{001B}[32m"
    public static let yellow = "\u{001B}[33m"
    public static let blue = "\u{001B}[34m"
    public static let cyan = "\u{001B}[36m"
    public static let red = "\u{001B}[31m"
    public static let magenta = "\u{001B}[35m"
}

class LoadingSpinner {
    private var isRunning = false
    private var spinnerThread: Thread?
    private let frames = ["◐", "◓", "◑", "◒"]
    private var currentFrame = 0

    func start() {
        guard !isRunning else { return }
        isRunning = true
        currentFrame = 0

        spinnerThread = Thread { [weak self] in
            guard let self = self else { return }

            while self.isRunning {
                print("\r\(Color.cyan)\(self.frames[self.currentFrame])\(Color.reset) ", terminator: "")
                fflush(stdout)

                self.currentFrame = (self.currentFrame + 1) % self.frames.count
                Thread.sleep(forTimeInterval: 0.1)
            }

            // Clear the spinner when done
            print("\r  \r", terminator: "")
            fflush(stdout)
        }

        spinnerThread?.start()
    }

    func stop() {
        isRunning = false
        spinnerThread = nil
    }
}

struct AgentResponse: Codable {
    let tool: String
    let action: String
    let explanation: String
    let needsAuth: Bool?
    let installViaBrew: String?

    enum CodingKeys: String, CodingKey {
        case tool
        case action
        case explanation
        case needsAuth = "needs_auth"
        case installViaBrew = "install_via_brew"
    }
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let messages: [ClaudeMessage]
    let maxTokens: Int
    let system: String?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case system
    }
}

struct ClaudeResponse: Codable {
    let id: String
    let content: [ContentBlock]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case stopReason = "stop_reason"
    }

    struct ContentBlock: Codable {
        let type: String
        let text: String
    }
}

public class Agent {
    private let config: GrinshConfig
    private let context: Context
    private let database: Database
    private let homebrew: Homebrew

    // Built-in tools
    private let fileSystemTool: FileSystemTool
    private let appsTool: AppsTool
    private let systemTool: SystemTool
    private let clipboardTool: ClipboardTool
    private let spotlightTool: SpotlightTool

    // Learned tools
    private var learnedTools: [String: LearnedTool] = [:]

    public init(config: GrinshConfig, context: Context, database: Database, homebrew: Homebrew) {
        self.config = config
        self.context = context
        self.database = database
        self.homebrew = homebrew

        // Initialize built-in tools
        self.fileSystemTool = FileSystemTool()
        self.appsTool = AppsTool()
        self.systemTool = SystemTool()
        self.clipboardTool = ClipboardTool()
        self.spotlightTool = SpotlightTool()

        // Load learned tools from database
        loadLearnedTools()
    }

    private func loadLearnedTools() {
        let tools = LearnedTool.loadFromDatabase(database: database, homebrew: homebrew)
        for tool in tools {
            learnedTools[tool.name] = tool
        }
    }

    public func clearContext() {
        context.clear()
    }

    public func processInput(_ input: String) -> String {
        // Add user message to context
        context.addUserMessage(input)

        // Call Claude API
        guard let response = callClaudeAPI() else {
            return "Error: Could not get response from Claude"
        }

        // Parse response
        guard let agentResponse = parseResponse(response) else {
            // If we can't parse as JSON, just return the text response
            context.addAssistantMessage(response)
            return response
        }

        // Show what we're doing
        print("\n\(Color.dim)\(agentResponse.explanation)\(Color.reset)")

        // Check if we need to install via brew
        if let brewPackage = agentResponse.installViaBrew {
            if !homebrew.isInstalled(package: brewPackage) {
                print("\n\(Color.yellow)Installing \(brewPackage) via Homebrew...\(Color.reset)")
                let (success, output) = homebrew.install(package: brewPackage)

                if !success {
                    let errorMsg = "Could not install \(brewPackage): \(output)"
                    context.addAssistantMessage(errorMsg)
                    return "\(Color.red)Error: \(errorMsg)\(Color.reset)"
                }

                print(output)

                // Create learned tool
                let learned = LearnedTool.create(
                    name: brewPackage,
                    description: "CLI tool installed via Homebrew",
                    usage: agentResponse.action,
                    examples: "",
                    database: database,
                    homebrew: homebrew
                )
                learnedTools[brewPackage] = learned
            }
        }

        // Execute the tool
        let result = executeTool(name: agentResponse.tool, action: agentResponse.action, needsAuth: agentResponse.needsAuth ?? false)

        // Store result in context
        context.addAssistantMessage(result)

        return result
    }

    private func callClaudeAPI() -> String? {
        guard !config.apiKey.isEmpty else {
            return "Error: No API key configured. Please add your Claude API key to ~/.grinshrc"
        }

        // Build request
        let messages = context.getMessages().map { msg in
            ClaudeMessage(role: msg.role, content: msg.content)
        }

        let request = ClaudeRequest(
            model: config.model,
            messages: messages,
            maxTokens: 4096,
            system: context.getSystemPrompt()
        )

        // Encode request
        guard let requestData = try? JSONEncoder().encode(request) else {
            return "Error: Could not encode request"
        }

        // Create HTTP request
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return "Error: Invalid API URL"
        }

        var httpRequest = URLRequest(url: url)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        httpRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        httpRequest.httpBody = requestData

        // Send request
        var responseData: Data?
        var responseError: Error?

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: httpRequest) { data, response, error in
            responseData = data
            responseError = error
            semaphore.signal()
        }

        // Start loading spinner
        let spinner = LoadingSpinner()
        spinner.start()

        task.resume()
        semaphore.wait()

        // Stop loading spinner
        spinner.stop()

        // Handle response
        if let error = responseError {
            return "Error: \(error.localizedDescription)"
        }

        guard let data = responseData else {
            return "Error: No response data"
        }

        // Decode response
        guard let claudeResponse = try? JSONDecoder().decode(ClaudeResponse.self, from: data) else {
            // Try to get error message from response
            if let errorStr = String(data: data, encoding: .utf8) {
                return "Error: \(errorStr)"
            }
            return "Error: Could not decode response"
        }

        // Extract text from response
        guard let firstBlock = claudeResponse.content.first else {
            return "Error: Empty response"
        }

        return firstBlock.text
    }

    private func parseResponse(_ response: String) -> AgentResponse? {
        // Try to extract JSON from the response
        // Claude might wrap JSON in markdown code blocks
        var jsonString = response

        if let jsonStart = response.range(of: "{"),
           let jsonEnd = response.range(of: "}", options: .backwards) {
            jsonString = String(response[jsonStart.lowerBound...jsonEnd.lowerBound])
        }

        guard let data = jsonString.data(using: .utf8),
              let agentResponse = try? JSONDecoder().decode(AgentResponse.self, from: data) else {
            return nil
        }

        return agentResponse
    }

    private func executeTool(name: String, action: String, needsAuth: Bool) -> String {
        // Check if auth is required
        if needsAuth {
            print("\nThis operation requires admin privileges.")
            let (success, output) = AuthTool.runWithAuth(command: action)
            return success ? output : "Error: \(output)"
        }

        // Execute built-in tools
        let result: ToolResult

        switch name.lowercased() {
        case "files", "filesystem":
            result = fileSystemTool.execute(action: action)
        case "apps", "applications":
            result = appsTool.execute(action: action)
        case "system":
            result = systemTool.execute(action: action)
        case "clipboard":
            result = clipboardTool.execute(action: action)
        case "spotlight", "search":
            result = spotlightTool.execute(action: action)
        default:
            // Check learned tools
            if let learnedTool = learnedTools[name] {
                result = learnedTool.execute(action: action)
            } else {
                // Try running as a CLI command directly
                let commandResult = runCommand(action)
                result = commandResult.exitCode == 0 ?
                    ToolResult.success(commandResult.output) :
                    ToolResult.failure(commandResult.output)
            }
        }

        if result.success {
            return "\(Color.green)\(result.output)\(Color.reset)"
        } else {
            return "\(Color.red)Error: \(result.error ?? "Unknown error")\(Color.reset)"
        }
    }

    private func runCommand(_ command: String) -> (output: String, exitCode: Int32) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", command]

        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe

        do {
            try task.run()
            task.waitUntilExit()

            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            var output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            if !errorOutput.isEmpty {
                output += "\n" + errorOutput
            }

            return (output.trimmingCharacters(in: .whitespacesAndNewlines), task.terminationStatus)
        } catch {
            return ("Error: \(error)", -1)
        }
    }
}
