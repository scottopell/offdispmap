//
//  logger.swift
//  offdispmap
//
//  Created by Scott Opell on 6/22/24.
//

import Foundation
import os.log

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    static let `default` = OSLog(subsystem: subsystem, category: "Default")

    static func debug(_ message: String, log: OSLog = Logger.default) {
        os_log(.debug, log: log, "%{public}@", message)
    }

    static func info(_ message: String, log: OSLog = Logger.default) {
        os_log(.info, log: log, "%{public}@", message)
    }

    static func `default`(_ message: String, log: OSLog = Logger.default) {
        os_log(.default, log: log, "%{public}@", message)
    }

    static func error(_ message: String, log: OSLog = Logger.default) {
        os_log(.error, log: log, "%{public}@", message)
    }
}

