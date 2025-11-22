import Foundation

class FileSystemTool: Tool {
    let name = "files"
    let description = "File operations: list, read, write, copy, move, delete, trash"

    private let fileManager = FileManager.default

    func execute(action: String) -> ToolResult {
        let parts = action.components(separatedBy: ":")
        guard let command = parts.first else {
            return .failure("Invalid action format")
        }

        switch command {
        case "list":
            return list(path: parts.count > 1 ? parts[1] : ".")
        case "read":
            guard parts.count > 1 else { return .failure("Missing file path") }
            return read(path: parts[1])
        case "write":
            guard parts.count > 2 else { return .failure("Missing file path or content") }
            return write(path: parts[1], content: parts[2])
        case "copy":
            guard parts.count > 2 else { return .failure("Missing source or destination") }
            return copy(from: parts[1], to: parts[2])
        case "move":
            guard parts.count > 2 else { return .failure("Missing source or destination") }
            return move(from: parts[1], to: parts[2])
        case "delete":
            guard parts.count > 1 else { return .failure("Missing file path") }
            return delete(path: parts[1])
        case "trash":
            guard parts.count > 1 else { return .failure("Missing file path") }
            return trash(path: parts[1])
        case "mkdir":
            guard parts.count > 1 else { return .failure("Missing directory path") }
            return makeDirectory(path: parts[1])
        case "info":
            guard parts.count > 1 else { return .failure("Missing file path") }
            return getInfo(path: parts[1])
        case "reveal":
            guard parts.count > 1 else { return .failure("Missing file path") }
            return reveal(path: parts[1])
        case "search":
            guard parts.count > 2 else { return .failure("Missing directory or pattern") }
            return search(directory: parts[1], pattern: parts[2])
        default:
            return .failure("Unknown command: \(command)")
        }
    }

    private func expandPath(_ path: String) -> String {
        if path.hasPrefix("~") {
            return NSString(string: path).expandingTildeInPath
        }
        return path
    }

    private func list(path: String) -> ToolResult {
        let expandedPath = expandPath(path)

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: expandedPath)
            let sorted = contents.sorted()

            var output = ""
            for item in sorted {
                let itemPath = (expandedPath as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                fileManager.fileExists(atPath: itemPath, isDirectory: &isDir)

                output += isDir.boolValue ? "\(item)/\n" : "\(item)\n"
            }

            return .success(output.isEmpty ? "(empty)" : output)
        } catch {
            return .failure("Error listing directory: \(error)")
        }
    }

    private func read(path: String) -> ToolResult {
        let expandedPath = expandPath(path)

        do {
            let contents = try String(contentsOfFile: expandedPath, encoding: .utf8)
            return .success(contents)
        } catch {
            return .failure("Error reading file: \(error)")
        }
    }

    private func write(path: String, content: String) -> ToolResult {
        let expandedPath = expandPath(path)

        do {
            try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)
            return .success("File written successfully")
        } catch {
            return .failure("Error writing file: \(error)")
        }
    }

    private func copy(from source: String, to destination: String) -> ToolResult {
        let expandedSource = expandPath(source)
        let expandedDest = expandPath(destination)

        do {
            try fileManager.copyItem(atPath: expandedSource, toPath: expandedDest)
            return .success("Copied \(source) to \(destination)")
        } catch {
            return .failure("Error copying file: \(error)")
        }
    }

    private func move(from source: String, to destination: String) -> ToolResult {
        let expandedSource = expandPath(source)
        let expandedDest = expandPath(destination)

        do {
            try fileManager.moveItem(atPath: expandedSource, toPath: expandedDest)
            return .success("Moved \(source) to \(destination)")
        } catch {
            return .failure("Error moving file: \(error)")
        }
    }

    private func delete(path: String) -> ToolResult {
        let expandedPath = expandPath(path)

        do {
            try fileManager.removeItem(atPath: expandedPath)
            return .success("Deleted \(path)")
        } catch {
            return .failure("Error deleting file: \(error)")
        }
    }

    private func trash(path: String) -> ToolResult {
        let expandedPath = expandPath(path)
        let url = URL(fileURLWithPath: expandedPath)

        do {
            try fileManager.trashItem(at: url, resultingItemURL: nil)
            return .success("Moved \(path) to trash")
        } catch {
            return .failure("Error moving to trash: \(error)")
        }
    }

    private func makeDirectory(path: String) -> ToolResult {
        let expandedPath = expandPath(path)

        do {
            try fileManager.createDirectory(atPath: expandedPath, withIntermediateDirectories: true)
            return .success("Created directory \(path)")
        } catch {
            return .failure("Error creating directory: \(error)")
        }
    }

    private func getInfo(path: String) -> ToolResult {
        let expandedPath = expandPath(path)

        do {
            let attrs = try fileManager.attributesOfItem(atPath: expandedPath)
            var info = "File: \(path)\n"

            if let size = attrs[.size] as? Int64 {
                info += "Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))\n"
            }

            if let modified = attrs[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                info += "Modified: \(formatter.string(from: modified))\n"
            }

            if let type = attrs[.type] as? FileAttributeType {
                info += "Type: \(type.rawValue)\n"
            }

            return .success(info)
        } catch {
            return .failure("Error getting file info: \(error)")
        }
    }

    private func reveal(path: String) -> ToolResult {
        let expandedPath = expandPath(path)
        let result = runCommand("open -R '\(expandedPath)'")

        if result.exitCode == 0 {
            return .success("Revealed \(path) in Finder")
        } else {
            return .failure("Error revealing file: \(result.output)")
        }
    }

    private func search(directory: String, pattern: String) -> ToolResult {
        let expandedDir = expandPath(directory)

        do {
            let enumerator = fileManager.enumerator(atPath: expandedDir)
            var matches: [String] = []

            while let file = enumerator?.nextObject() as? String {
                if file.localizedCaseInsensitiveContains(pattern) {
                    matches.append(file)
                }
            }

            if matches.isEmpty {
                return .success("No matches found")
            } else {
                return .success(matches.joined(separator: "\n"))
            }
        } catch {
            return .failure("Error searching: \(error)")
        }
    }
}
