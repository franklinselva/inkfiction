import Foundation
import OSLog

// MARK: - Log Categories

/// Categories for organizing log messages
enum LogCategory: String, CaseIterable {
    case app = "App"
    case navigation = "Navigation"
    case data = "Data"
    case cloudKit = "CloudKit"
    case biometric = "Biometric"
    case ai = "AI"
    case subscription = "Subscription"
    case ui = "UI"
    case persona = "Persona"
    case journal = "Journal"
    case settings = "Settings"
    case analytics = "Analytics"
    case moodAnalysis = "MoodAnalysis"
    case notifications = "Notifications"

    var subsystem: String {
        "com.quantumtech.InkFiction.\(rawValue)"
    }
}

// MARK: - Log

/// Unified logging interface using Apple's OSLog
enum Log {

    private static var loggers: [LogCategory: Logger] = [:]

    private static func logger(for category: LogCategory) -> Logger {
        if let existing = loggers[category] {
            return existing
        }
        let newLogger = Logger(subsystem: category.subsystem, category: category.rawValue)
        loggers[category] = newLogger
        return newLogger
    }

    static func debug(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = formatContext(file: file, function: function, line: line)
        logger(for: category).debug("[\(context)] \(message)")
    }

    static func info(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = formatContext(file: file, function: function, line: line)
        logger(for: category).info("[\(context)] \(message)")
    }

    static func warning(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = formatContext(file: file, function: function, line: line)
        logger(for: category).warning("[\(context)] \(message)")
    }

    static func error(
        _ message: String,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = formatContext(file: file, function: function, line: line)
        logger(for: category).error("[\(context)] \(message)")
    }

    static func error(
        _ message: String,
        error: Error,
        category: LogCategory = .app,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let context = formatContext(file: file, function: function, line: line)
        logger(for: category).error("[\(context)] \(message): \(error.localizedDescription)")
    }

    private static func formatContext(file: String, function: String, line: Int) -> String {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        return "\(fileName):\(line)"
    }
}

// MARK: - Signpost Support

extension Log {

    static func signpostBegin(_ name: StaticString, category: LogCategory = .app) -> OSSignpostID {
        let log = OSLog(subsystem: category.subsystem, category: category.rawValue)
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        return signpostID
    }

    static func signpostEnd(_ name: StaticString, signpostID: OSSignpostID, category: LogCategory = .app) {
        let log = OSLog(subsystem: category.subsystem, category: category.rawValue)
        os_signpost(.end, log: log, name: name, signpostID: signpostID)
    }
}
