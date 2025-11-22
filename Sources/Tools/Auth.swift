import Foundation
import Security

class AuthTool {
    static func requestAuthorization(for operation: String) -> Bool {
        // Create authorization reference
        var authRef: AuthorizationRef?

        let flags: AuthorizationFlags = [
            .interactionAllowed,
            .extendRights,
            .preAuthorize
        ]

        // Use withCString and withUnsafeMutablePointer to properly manage pointers
        return kAuthorizationRightExecute.withCString { namePtr in
            var authItem = AuthorizationItem(
                name: namePtr,
                valueLength: 0,
                value: nil,
                flags: 0
            )

            return withUnsafeMutablePointer(to: &authItem) { itemPtr in
                var authRights = AuthorizationRights(
                    count: 1,
                    items: itemPtr
                )

                let status = AuthorizationCreate(
                    &authRights,
                    nil,
                    flags,
                    &authRef
                )

                if status == errAuthorizationSuccess {
                    if let auth = authRef {
                        AuthorizationFree(auth, [])
                    }
                    return true
                }

                return false
            }
        }
    }

    static func runWithAuth(command: String) -> (success: Bool, output: String) {
        // Request authorization
        guard requestAuthorization(for: command) else {
            return (false, "Authorization denied")
        }

        // Run command with admin privileges using osascript
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escapedCommand)\" with administrator privileges"

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]

        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe

        do {
            try task.run()
            task.waitUntilExit()

            let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            let output = String(data: outputData, encoding: .utf8) ?? ""
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

            let success = task.terminationStatus == 0
            return (success, success ? output : errorOutput)
        } catch {
            return (false, "Error: \(error)")
        }
    }
}
