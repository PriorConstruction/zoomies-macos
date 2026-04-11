//
//  Logger.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Logging helper so session flow and actions are easy to trace.

import Foundation
// This is to keep the debug output consistent across the whole app.
enum Logger {
    static func log(_ message: String) {
        print("[Zoomies] \(message)")
    }
}
