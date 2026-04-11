//
//  SessionOptions.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// We have this to store the currentl selected options for the active session.

import Foundation

struct SessionOptions: Codable {
    var restoreAppsAfterSession: Bool
    var enableMetalHUD: Bool
    var enableHighPowerMode: Bool
    var launchAtLogin: Bool
    var protectedBundleIDs: Set<String>
    // These are our default settings that will be used on the first launch. 
    static let `default` = SessionOptions(
        restoreAppsAfterSession: true,
        enableMetalHUD: false,
        enableHighPowerMode: false,
        launchAtLogin: false,
        protectedBundleIDs: Set(
            ProtectedApp.default
                .filter(\.isEnabledByDefault)
                .flatMap(\.bundleIDs)
        )
    )
}
