import Foundation

class Homebrew {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func isInstalled(package: String) -> Bool {
        // First check cache
        if let cached = try? database.getBrewPackage(name: package) {
            let age = Date().timeIntervalSince(cached.updatedAt)
            // Cache valid for 1 hour
            if age < 3600 {
                return cached.installed
            }
        }

        // Check actual installation
        let installed = checkActualInstallation(package: package)

        // Update cache
        try? database.updateBrewCache(
            name: package,
            installed: installed,
            description: ""
        )

        return installed
    }

    private func checkActualInstallation(package: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "command -v \(package) > /dev/null 2>&1"]

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    func install(package: String) -> (success: Bool, output: String) {
        print("Installing \(package) via Homebrew...")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["brew", "install", package]

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

            // Update cache
            try? database.updateBrewCache(
                name: package,
                installed: success,
                description: ""
            )

            return (success, success ? output : errorOutput)
        } catch {
            return (false, "Failed to run brew: \(error)")
        }
    }

    func search(package: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["brew", "search", package]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func info(package: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["brew", "info", package]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func getInstalledPackages() -> [String] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["brew", "list"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
        } catch {
            return []
        }

        return []
    }

    static func isBrewAvailable() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "command -v brew > /dev/null 2>&1"]

        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
}
