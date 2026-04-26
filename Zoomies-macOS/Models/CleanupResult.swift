//
//  CleanupResult.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This stores what Zoomies plans to close, what it actually closed and anything it had left alone.

import Foundation

struct CleanupResult {
    var candidateApps: [ClosedApp]
    var closedApps: [ClosedApp]
    var skippedApps: [String]
    var failedApps: [String]

    static let empty = CleanupResult(
        candidateApps: [],
        closedApps: [],
        skippedApps: [],
        failedApps: []
    )
}

// A record so that those apps can thenn be reopened later.
// We keep the bundle URL instead of only the app name because names are not reliable identifiers.
struct ClosedApp: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let bundleID: String
    let bundleURL: URL?

    init(name: String, bundleID: String, bundleURL: URL?) {
        self.id = bundleID
        self.name = name
        self.bundleID = bundleID
        self.bundleURL = bundleURL
    }
}
