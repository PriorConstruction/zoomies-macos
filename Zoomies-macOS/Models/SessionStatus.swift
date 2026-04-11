//
//  SessionStatus.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The states to be used by the menu bar UI and the main window.

import Foundation

enum SessionStatus: Equatable {
    case ready
    case active(closedCount: Int)
    case ended(closedCount: Int)
    case restored
}
