import Foundation
import AppKit

class AppsTool: Tool {
    let name = "apps"
    let description = "Application management: list, launch, quit, hide, activate"

    func execute(action: String) -> ToolResult {
        let parts = action.components(separatedBy: ":")
        guard let command = parts.first else {
            return .failure("Invalid action format")
        }

        switch command {
        case "list":
            return listRunning()
        case "launch":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return launch(app: parts[1])
        case "quit":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return quit(app: parts[1], force: false)
        case "force-quit":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return quit(app: parts[1], force: true)
        case "hide":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return hide(app: parts[1])
        case "unhide":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return unhide(app: parts[1])
        case "activate":
            guard parts.count > 1 else { return .failure("Missing app name") }
            return activate(app: parts[1])
        case "frontmost":
            return getFrontmost()
        default:
            return .failure("Unknown command: \(command)")
        }
    }

    private func listRunning() -> ToolResult {
        let workspace = NSWorkspace.shared
        let apps = workspace.runningApplications

        var output = ""
        for app in apps {
            if let name = app.localizedName, app.activationPolicy == .regular {
                let active = app.isActive ? " (active)" : ""
                let hidden = app.isHidden ? " (hidden)" : ""
                output += "\(name)\(active)\(hidden)\n"
            }
        }

        return .success(output.isEmpty ? "No applications running" : output)
    }

    private func findApp(name: String) -> NSRunningApplication? {
        let workspace = NSWorkspace.shared
        let apps = workspace.runningApplications

        // Try exact match first
        if let app = apps.first(where: { $0.localizedName?.lowercased() == name.lowercased() }) {
            return app
        }

        // Try contains match
        return apps.first(where: { $0.localizedName?.lowercased().contains(name.lowercased()) ?? false })
    }

    private func launch(app: String) -> ToolResult {
        let workspace = NSWorkspace.shared

        // Try to find app by name in /Applications
        let appPath = "/Applications/\(app).app"
        let appURL = URL(fileURLWithPath: appPath)

        if FileManager.default.fileExists(atPath: appPath) {
            let config = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: appURL, configuration: config) { runningApp, error in
                // Completion handler - we don't wait for it in this synchronous API
            }
            return .success("Launched \(app)")
        }

        // Try using open command
        let result = runCommand("open -a '\(app)'")
        if result.exitCode == 0 {
            return .success("Launched \(app)")
        } else {
            return .failure("Could not launch \(app): \(result.output)")
        }
    }

    private func quit(app: String, force: Bool) -> ToolResult {
        guard let runningApp = findApp(name: app) else {
            return .failure("App not running: \(app)")
        }

        let success = force ? runningApp.forceTerminate() : runningApp.terminate()

        if success {
            return .success("Quit \(app)")
        } else {
            return .failure("Could not quit \(app)")
        }
    }

    private func hide(app: String) -> ToolResult {
        guard let runningApp = findApp(name: app) else {
            return .failure("App not running: \(app)")
        }

        let success = runningApp.hide()

        if success {
            return .success("Hid \(app)")
        } else {
            return .failure("Could not hide \(app)")
        }
    }

    private func unhide(app: String) -> ToolResult {
        guard let runningApp = findApp(name: app) else {
            return .failure("App not running: \(app)")
        }

        let success = runningApp.unhide()

        if success {
            return .success("Unhid \(app)")
        } else {
            return .failure("Could not unhide \(app)")
        }
    }

    private func activate(app: String) -> ToolResult {
        guard let runningApp = findApp(name: app) else {
            return .failure("App not running: \(app)")
        }

        let success = runningApp.activate(options: [.activateIgnoringOtherApps])

        if success {
            return .success("Activated \(app)")
        } else {
            return .failure("Could not activate \(app)")
        }
    }

    private func getFrontmost() -> ToolResult {
        let workspace = NSWorkspace.shared

        if let app = workspace.frontmostApplication,
           let name = app.localizedName {
            return .success("Frontmost app: \(name)")
        } else {
            return .failure("Could not determine frontmost app")
        }
    }
}
