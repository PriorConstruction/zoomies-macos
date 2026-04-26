//
//  CustomProtectedApp.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// User added protected apps/software.
// This will let people protect their own launchers, tools or other Mac apps that Zoomies doesn't know about yet.

import Foundation

struct CustomProtectedApp: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let bundleID: String
    let appURL: URL

    init(id: UUID = UUID(), name: String, bundleID: String, appURL: URL) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.appURL = appURL
    }
}
