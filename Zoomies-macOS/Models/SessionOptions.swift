//
//  SessionOptions.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// We have this to store the currently selected options for the active session.

import Foundation

struct SessionOptions: Codable, Equatable {
    var restoreAppsAfterSession: Bool
    var enableMetalHUD: Bool
    var enableHighPowerModeShortcut: Bool
    var launchAtLogin: Bool
    var protectedBundleIDs: Set<String>

    // These are our default settings that will be used on the first launch.
    static let `default` = SessionOptions(
        restoreAppsAfterSession: true,
        enableMetalHUD: false,
        enableHighPowerModeShortcut: false,
        launchAtLogin: false,
        protectedBundleIDs: Set(
            ProtectedApp.default
                .filter(\.isEnabledByDefault)
                .flatMap(\.bundleIDs)
        )
    )
}
