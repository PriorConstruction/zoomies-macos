//
//  CleanupResult.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This is to store what Zoomies closed for us during the session.

import Foundation

struct CleanupResult {
    var closedApps: [ClosedApp]
    var skippedApps: [String]
    var failedApps: [String]

    static let empty = CleanupResult(
        closedApps: [],
        skippedApps: [],
        failedApps: []
    )
}
// A record so that those apps can be reopened later.
struct ClosedApp: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let bundleID: String
    let executableURL: URL?

    init(name: String, bundleID: String, executableURL: URL?) {
        self.id = bundleID
        self.name = name
        self.bundleID = bundleID
        self.executableURL = executableURL
    }
}
