import Foundation

// Signal handling
var shouldExit = false

func setupSignalHandlers() {
    signal(SIGINT) { _ in
        print("\n\nUse 'exit' or 'quit' to exit grinsh")
    }

    signal(SIGTERM) { _ in
        shouldExit = true
    }
}

// Main REPL loop
func runREPL(agent: Agent) {
    print("grinsh - conversational shell")
    print("Type your request in natural language")
    print("Type 'exit' or 'quit' to exit")
    print("Type '!command' to run raw shell commands")
    print("Type 'clear' to clear conversation history")
    print("")

    while !shouldExit {
        // Print prompt
        print("> ", terminator: "")
        fflush(stdout)

        // Read input
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            continue
        }

        // Skip empty input
        if input.isEmpty {
            continue
        }

        // Handle special commands
        switch input.lowercased() {
        case "exit", "quit":
            print("Goodbye!")
            return

        case "clear":
            agent.clearContext()
            print("Conversation history cleared")
            continue

        case let cmd where cmd.hasPrefix("!"):
            // Raw command execution
            let command = String(cmd.dropFirst())
            let result = runRawCommand(command)
            print(result)
            continue

        default:
            break
        }

        // Process with agent
        let response = agent.processInput(input)
        print("\n\(response)\n")
    }
}

// Run raw shell command
func runRawCommand(_ command: String) -> String {
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

        return output
    } catch {
        return "Error: \(error)"
    }
}

// Handle command line arguments
func handleArguments(_ args: [String]) {
    // Handle shell flags
    if args.contains("-l") || args.contains("--login") {
        // Login shell - just continue to REPL
        return
    }

    if let cIndex = args.firstIndex(of: "-c") {
        // Non-interactive command execution
        guard args.count > cIndex + 1 else {
            print("Error: -c requires a command")
            exit(1)
        }

        let command = args[cIndex + 1]
        let result = runRawCommand(command)
        print(result)
        exit(0)
    }
}

// Main entry point
func main() {
    let args = CommandLine.arguments

    // Handle command line arguments
    if args.count > 1 {
        handleArguments(args)
    }

    // Setup signal handlers
    setupSignalHandlers()

    // Load configuration
    let config = Config.load()

    if config.apiKey.isEmpty {
        print("Error: No API key configured")
        print("\nPlease create ~/.grinshrc with your Claude API key:")
        print("api_key = \"sk-ant-...\"")
        print("model = \"claude-sonnet-4-20250514\"")
        print("context_limit = 50")
        exit(1)
    }

    // Initialize database
    guard let database = try? Database() else {
        print("Error: Could not initialize database")
        exit(1)
    }

    // Initialize homebrew
    let homebrew = Homebrew(database: database)

    // Check if Homebrew is available
    if !Homebrew.isBrewAvailable() {
        print("Warning: Homebrew not found. CLI tool installation will not be available.")
        print("Install Homebrew from https://brew.sh")
    }

    // Initialize context
    let context = Context(database: database, config: config)

    // Initialize agent
    let agent = Agent(config: config, context: context, database: database, homebrew: homebrew)

    // Run REPL
    runREPL(agent: agent)
}

// Run main
main()
