//
//  SessionStatus.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The states used by the menu bar UI and the preview flow.
// Keeping this small makes it easier to reason about what Zoomies is doing.

import Foundation

enum SessionStatus: Equatable {
    case ready
    case previewing(count: Int)
    case preparing
    case active(closedCount: Int)
    case ended(closedCount: Int)
    case restored(restoredCount: Int)
    case failed(message: String)
}
