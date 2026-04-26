//
//  RestoreService.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This is the lightweight list of any closed apps so they can be restored later.
// v1.1 persists the manifest so the restore list survives a quit and/or crash better than memory alone.

import AppKit
import Foundation

final class RestoreService {
    private(set) var recentlyClosedApps: [ClosedApp] = []
    private let defaults = UserDefaults.standard

    init() {
        recentlyClosedApps = loadStoredApps()
    }

    // Save the result for the future restore action.
    func storeClosedApps(_ apps: [ClosedApp]) {
        recentlyClosedApps = apps
        persistClosedApps(apps)
        Logger.log("Stored \(apps.count) app(s) for restore")
    }

    // To reopen every app from the recent cleanup
    @discardableResult
    func restoreApps() -> Int {
        guard !recentlyClosedApps.isEmpty else {
            Logger.log("No apps to restore")
            return 0
        }

        var restoreCount = 0

        for app in recentlyClosedApps {
            guard let appURL = app.bundleURL else {
                Logger.log("Missing URL for \(app.name), skipping restore")
                continue
            }

            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false
            configuration.createsNewApplicationInstance = false

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

            restoreCount += 1
        }

        // This should clear the restore list so next session started is fresh.
        recentlyClosedApps.removeAll()
        persistClosedApps([])

        return restoreCount
    }

    private func persistClosedApps(_ apps: [ClosedApp]) {
        do {
            let data = try JSONEncoder().encode(apps)
            defaults.set(data, forKey: AppStorageKeys.pendingRestoreManifest)
        } catch {
            Logger.log("Failed to persist restore manifest: \(error.localizedDescription)")
        }
    }

    private func loadStoredApps() -> [ClosedApp] {
        guard let data = defaults.data(forKey: AppStorageKeys.pendingRestoreManifest) else {
            return []
        }

        do {
            return try JSONDecoder().decode([ClosedApp].self, from: data)
        } catch {
            Logger.log("Failed to load restore manifest: \(error.localizedDescription)")
            return []
        }
    }
}
