import Foundation
import SQLite

struct Message {
    let id: Int64
    let role: String
    let content: String
    let timestamp: Date
}

struct ToolRecord {
    let id: Int64
    let name: String
    let description: String
    let usage: String
    let examples: String
    let learnedAt: Date
}

struct BrewPackage {
    let name: String
    let installed: Bool
    let description: String
    let updatedAt: Date
}

public class Database {
    private let db: Connection
    private let dbPath: String

    // Tables
    private let messages = Table("messages")
    private let tools = Table("tools")
    private let brewCache = Table("brew_cache")
    private let preferences = Table("preferences")
    private let history = Table("history")

    // Messages columns
    private let msgId = Expression<Int64>("id")
    private let msgRole = Expression<String>("role")
    private let msgContent = Expression<String>("content")
    private let msgTimestamp = Expression<Date>("timestamp")

    // Tools columns
    private let toolId = Expression<Int64>("id")
    private let toolName = Expression<String>("name")
    private let toolDescription = Expression<String>("description")
    private let toolUsage = Expression<String>("usage")
    private let toolExamples = Expression<String>("examples")
    private let toolLearnedAt = Expression<Date>("learned_at")

    // Brew cache columns
    private let brewName = Expression<String>("name")
    private let brewInstalled = Expression<Bool>("installed")
    private let brewDescription = Expression<String>("description")
    private let brewUpdatedAt = Expression<Date>("updated_at")

    // Preferences columns
    private let prefKey = Expression<String>("key")
    private let prefValue = Expression<String>("value")

    // History columns
    private let histId = Expression<Int64>("id")
    private let histInput = Expression<String>("input")
    private let histTimestamp = Expression<Date>("timestamp")

    public init() throws {
        // Create ~/.grinsh directory if it doesn't exist
        let grinshDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".grinsh")

        if !FileManager.default.fileExists(atPath: grinshDir.path) {
            try FileManager.default.createDirectory(at: grinshDir, withIntermediateDirectories: true)
        }

        dbPath = grinshDir.appendingPathComponent("grinsh.db").path
        db = try Connection(dbPath)

        try createTables()
    }

    static func createForTesting(at path: String) throws -> Database {
        let instance = try Database.__createWithPath(path)
        return instance
    }

    private init(dbPath: String) throws {
        self.dbPath = dbPath
        self.db = try Connection(dbPath)
        try createTables()
    }

    private static func __createWithPath(_ path: String) throws -> Database {
        return try Database(dbPath: path)
    }

    private func createTables() throws {
        // Messages table
        try db.run(messages.create(ifNotExists: true) { t in
            t.column(msgId, primaryKey: .autoincrement)
            t.column(msgRole)
            t.column(msgContent)
            t.column(msgTimestamp)
        })

        // Tools table
        try db.run(tools.create(ifNotExists: true) { t in
            t.column(toolId, primaryKey: .autoincrement)
            t.column(toolName, unique: true)
            t.column(toolDescription)
            t.column(toolUsage)
            t.column(toolExamples)
            t.column(toolLearnedAt)
        })

        // Brew cache table
        try db.run(brewCache.create(ifNotExists: true) { t in
            t.column(brewName, primaryKey: true)
            t.column(brewInstalled)
            t.column(brewDescription)
            t.column(brewUpdatedAt)
        })

        // Preferences table
        try db.run(preferences.create(ifNotExists: true) { t in
            t.column(prefKey, primaryKey: true)
            t.column(prefValue)
        })

        // History table
        try db.run(history.create(ifNotExists: true) { t in
            t.column(histId, primaryKey: .autoincrement)
            t.column(histInput)
            t.column(histTimestamp)
        })
    }

    // MARK: - Messages

    func addMessage(role: String, content: String) throws -> Int64 {
        let insert = messages.insert(
            msgRole <- role,
            msgContent <- content,
            msgTimestamp <- Date()
        )
        return try db.run(insert)
    }

    func getRecentMessages(limit: Int) throws -> [Message] {
        var result: [Message] = []
        let query = messages
            .order(msgId.desc)
            .limit(limit)

        for row in try db.prepare(query) {
            result.append(Message(
                id: row[msgId],
                role: row[msgRole],
                content: row[msgContent],
                timestamp: row[msgTimestamp]
            ))
        }

        return result.reversed()
    }

    func clearMessages() throws {
        try db.run(messages.delete())
    }

    // MARK: - Tools

    func saveTool(name: String, description: String, usage: String, examples: String) throws {
        let insert = tools.insert(or: .replace,
            toolName <- name,
            toolDescription <- description,
            toolUsage <- usage,
            toolExamples <- examples,
            toolLearnedAt <- Date()
        )
        try db.run(insert)
    }

    func getTool(name: String) throws -> ToolRecord? {
        let query = tools.filter(toolName == name)
        guard let row = try db.pluck(query) else {
            return nil
        }

        return ToolRecord(
            id: row[toolId],
            name: row[toolName],
            description: row[toolDescription],
            usage: row[toolUsage],
            examples: row[toolExamples],
            learnedAt: row[toolLearnedAt]
        )
    }

    func getAllTools() throws -> [ToolRecord] {
        var result: [ToolRecord] = []
        for row in try db.prepare(tools) {
            result.append(ToolRecord(
                id: row[toolId],
                name: row[toolName],
                description: row[toolDescription],
                usage: row[toolUsage],
                examples: row[toolExamples],
                learnedAt: row[toolLearnedAt]
            ))
        }
        return result
    }

    // MARK: - Brew Cache

    func updateBrewCache(name: String, installed: Bool, description: String) throws {
        let insert = brewCache.insert(or: .replace,
            brewName <- name,
            brewInstalled <- installed,
            brewDescription <- description,
            brewUpdatedAt <- Date()
        )
        try db.run(insert)
    }

    func getBrewPackage(name: String) throws -> BrewPackage? {
        let query = brewCache.filter(brewName == name)
        guard let row = try db.pluck(query) else {
            return nil
        }

        return BrewPackage(
            name: row[brewName],
            installed: row[brewInstalled],
            description: row[brewDescription],
            updatedAt: row[brewUpdatedAt]
        )
    }

    func isBrewPackageInstalled(name: String) throws -> Bool {
        if let package = try getBrewPackage(name: name) {
            return package.installed
        }
        return false
    }

    // MARK: - Preferences

    func setPreference(key: String, value: String) throws {
        let insert = preferences.insert(or: .replace,
            prefKey <- key,
            prefValue <- value
        )
        try db.run(insert)
    }

    func getPreference(key: String) throws -> String? {
        let query = preferences.filter(prefKey == key)
        return try db.pluck(query)?[prefValue]
    }

    // MARK: - History

    func addHistory(input: String) throws {
        let insert = history.insert(
            histInput <- input,
            histTimestamp <- Date()
        )
        try db.run(insert)
    }

    func getHistory(limit: Int = 100) throws -> [(id: Int64, input: String, timestamp: Date)] {
        var result: [(Int64, String, Date)] = []
        let query = history
            .order(histId.desc)
            .limit(limit)

        for row in try db.prepare(query) {
            result.append((row[histId], row[histInput], row[histTimestamp]))
        }

        return result.reversed()
    }
}
