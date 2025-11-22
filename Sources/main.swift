import Foundation
import GrinshCore

#if canImport(Darwin)
import Darwin
#endif

// Command history
var commandHistory: [String] = []
var historyIndex: Int = 0

// Terminal settings
var originalTermios: termios = termios()

// Signal handling
var shouldExit = false
var currentAgent: Agent?

// Terminal raw mode functions
func enableRawMode() {
    tcgetattr(STDIN_FILENO, &originalTermios)
    var raw = originalTermios
    raw.c_lflag &= ~(UInt(ECHO | ICANON))
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
}

func disableRawMode() {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
}

func setupSignalHandlers() {
    signal(SIGINT) { _ in
        // Try to cancel current request first
        if let agent = currentAgent {
            agent.cancelCurrentRequest()
            print("\n")
        } else {
            print("\n\n\(Color.dim)Use 'exit' or 'quit' to exit grinsh\(Color.reset)")
        }
        // Redisplay prompt
        print("\(Color.blue)>\(Color.reset) ", terminator: "")
        fflush(stdout)
    }

    signal(SIGTERM) { _ in
        disableRawMode()
        shouldExit = true
    }
}

// Read line with history support
func readLineWithHistory() -> String? {
    enableRawMode()
    defer { disableRawMode() }

    var currentLine = ""
    var cursorPos = 0
    historyIndex = commandHistory.count

    while true {
        guard let char = getChar() else { continue }

        // Handle special keys
        if char == 127 || char == 8 {  // Backspace or Delete
            if cursorPos > 0 {
                currentLine.remove(at: currentLine.index(currentLine.startIndex, offsetBy: cursorPos - 1))
                cursorPos -= 1
                redrawLine(currentLine, cursorPos: cursorPos)
            }
        } else if char == 27 {  // ESC - arrow keys
            let next1 = getChar()
            let next2 = getChar()

            if next1 == 91 {  // '[' - ANSI escape sequence
                if next2 == 65 {  // Up arrow
                    if historyIndex > 0 {
                        historyIndex -= 1
                        currentLine = commandHistory[historyIndex]
                        cursorPos = currentLine.count
                        redrawLine(currentLine, cursorPos: cursorPos)
                    }
                } else if next2 == 66 {  // Down arrow
                    if historyIndex < commandHistory.count - 1 {
                        historyIndex += 1
                        currentLine = commandHistory[historyIndex]
                        cursorPos = currentLine.count
                        redrawLine(currentLine, cursorPos: cursorPos)
                    } else if historyIndex == commandHistory.count - 1 {
                        historyIndex = commandHistory.count
                        currentLine = ""
                        cursorPos = 0
                        redrawLine(currentLine, cursorPos: cursorPos)
                    }
                } else if next2 == 67 {  // Right arrow
                    if cursorPos < currentLine.count {
                        cursorPos += 1
                        redrawLine(currentLine, cursorPos: cursorPos)
                    }
                } else if next2 == 68 {  // Left arrow
                    if cursorPos > 0 {
                        cursorPos -= 1
                        redrawLine(currentLine, cursorPos: cursorPos)
                    }
                }
            }
        } else if char == 13 || char == 10 {  // Enter/Return
            print("")
            return currentLine
        } else if char >= 32 && char < 127 {  // Printable characters
            let character = Character(UnicodeScalar(char))
            currentLine.insert(character, at: currentLine.index(currentLine.startIndex, offsetBy: cursorPos))
            cursorPos += 1
            redrawLine(currentLine, cursorPos: cursorPos)
        }
    }
}

func getChar() -> UInt8? {
    var c: UInt8 = 0
    let result = read(STDIN_FILENO, &c, 1)
    return result == 1 ? c : nil
}

func redrawLine(_ line: String, cursorPos: Int) {
    // Clear line and redraw
    print("\r\u{001B}[K\(Color.blue)>\(Color.reset) \(line)", terminator: "")

    // Move cursor to correct position
    // Position is: "> " (2 chars) + cursorPos
    let targetColumn = cursorPos + 2
    print("\r\u{001B}[\(targetColumn)C", terminator: "")
    fflush(stdout)
}

// Main REPL loop
func runREPL(agent: Agent) {
    print("\(Color.bold)\(Color.green)grinsh\(Color.reset) - conversational shell")
    print("\(Color.dim)Type your request in natural language\(Color.reset)")
    print("\(Color.dim)Type 'exit' or 'quit' to exit\(Color.reset)")
    print("\(Color.dim)Type '!command' to run raw shell commands\(Color.reset)")
    print("\(Color.dim)Type 'clear' to clear conversation history\(Color.reset)")
    print("")

    while !shouldExit {
        // Print prompt
        print("\(Color.blue)>\(Color.reset) ", terminator: "")
        fflush(stdout)

        // Read input with history support
        guard let input = readLineWithHistory()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            continue
        }

        // Skip empty input
        if input.isEmpty {
            continue
        }

        // Add to history
        if !input.isEmpty && (commandHistory.isEmpty || commandHistory.last != input) {
            commandHistory.append(input)
        }

        // Handle special commands
        switch input.lowercased() {
        case "exit", "quit":
            print("\(Color.green)Goodbye!\(Color.reset)")
            disableRawMode()
            return

        case "clear":
            agent.clearContext()
            print("\(Color.yellow)Conversation history cleared\(Color.reset)")
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
        currentAgent = agent
        let response = agent.processInput(input)
        currentAgent = nil
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
        print("\(Color.red)Error: No API key configured\(Color.reset)")
        print("\n\(Color.yellow)Please create ~/.grinshrc with your Claude API key:\(Color.reset)")
        print("\(Color.dim)api_key = \"sk-ant-...\"\(Color.reset)")
        print("\(Color.dim)model = \"claude-sonnet-4-20250514\"\(Color.reset)")
        print("\(Color.dim)context_limit = 50\(Color.reset)")
        exit(1)
    }

    // Initialize database
    guard let database = try? Database() else {
        print("\(Color.red)Error: Could not initialize database\(Color.reset)")
        exit(1)
    }

    // Initialize homebrew
    let homebrew = Homebrew(database: database)

    // Check if Homebrew is available
    if !Homebrew.isBrewAvailable() {
        print("\(Color.yellow)Warning: Homebrew not found. CLI tool installation will not be available.\(Color.reset)")
        print("\(Color.dim)Install Homebrew from https://brew.sh\(Color.reset)")
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
