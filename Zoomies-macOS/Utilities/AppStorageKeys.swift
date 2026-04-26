//
//  AppStorageKeys.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The shared UserDefaults keys used across onboarding, settings and the session state.

import Foundation

enum AppStorageKeys {
    static let hasSeenWelcome = "hasSeenWelcome"
    static let sessionOptions = "sessionOptions"
    static let selectedProfile = "selectedProfile"
    static let pendingRestoreManifest = "pendingRestoreManifest"
    static let customProtectedApps = "customProtectedApps"
}
