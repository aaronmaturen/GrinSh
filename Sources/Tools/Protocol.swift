import Foundation

enum ToolError: Error {
    case executionFailed(String)
    case authRequired
    case notFound
    case invalidInput(String)
}

struct ToolResult {
    let success: Bool
    let output: String
    let error: String?

    static func success(_ output: String) -> ToolResult {
        return ToolResult(success: true, output: output, error: nil)
    }

    static func failure(_ error: String) -> ToolResult {
        return ToolResult(success: false, output: "", error: error)
    }
}

protocol Tool {
    var name: String { get }
    var description: String { get }

    func execute(action: String) -> ToolResult
}

extension Tool {
    func runCommand(_ command: String) -> (output: String, exitCode: Int32) {
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
