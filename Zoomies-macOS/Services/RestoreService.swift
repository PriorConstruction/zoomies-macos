//
//  RestoreService.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This is the lightweight list of any closed apps so they can be restored lateer.

import AppKit
import Foundation

final class RestoreService {
    private(set) var recentlyClosedApps: [ClosedApp] = []
    // Save the result for the future restore action.
    func storeClosedApps(_ apps: [ClosedApp]) {
        recentlyClosedApps = apps
        Logger.log("Stored \(apps.count) app(s) for restore")
    }
    // To reopen every app from the recent cleanup.
    func restoreApps() {
        guard !recentlyClosedApps.isEmpty else {
            Logger.log("No apps to restore")
            return
        }
        // If there's no executable path, it can be skipped with this.
        for app in recentlyClosedApps {
            guard let appURL = app.executableURL else {
                Logger.log("Missing URL for \(app.name), skipping restore")
                continue
            }
            
            let configuration = NSWorkspace.OpenConfiguration()
            
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: configuration
            ) { _, error in
                if let error {
                    Logger.log("Failed to restore \(app.name): \(error.localizedDescription)")
                } else {
                    Logger.log("Restored app: \(app.name)")
                }
            }
        }
        // This should clear the restore list so next session started is fresh.
        recentlyClosedApps.removeAll()
    }
}
