//
//  ProcessCleanupService.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This is to find the running apps and safely close down anything that isn't protected.
// Zoomies asks normal user apps to quit. It does not inject, patch or mess with the system.

import AppKit
import Foundation

final class ProcessCleanupService {
    private let alwaysProtectedBundleIDs: Set<String> = [
        Bundle.main.bundleIdentifier ?? "",

        // These will never be closed/protected at all times regardless of profile - important apps and system processes and the macOS core tools.
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systempreferences",
        "com.apple.systemsettings",
        "com.apple.controlcenter",
        "com.apple.TextInputMenuAgent",
        "com.apple.TextInputSwitcher",
        "com.apple.systemuiserver",
        "com.apple.SystemUIServer",
        "com.apple.notificationcenterui",
        "com.apple.UserNotificationCenter",
        "com.apple.loginwindow",
        "com.apple.WindowManager",
        "com.apple.wifi.WiFiAgent",
        "com.apple.airport.airportutility",
        "com.apple.WirelessDiagnostics",
        "com.apple.ActivityMonitor",
        "com.apple.Spotlight",
        "com.apple.ScreenContinuity",
        "com.apple.SecurityAgent"
    ]

    // Start with all of the running apps then narrow it down to only normal user apps that are safe to close.
    func candidateAppsForClosure(protectedBundleIDs: Set<String>) -> [NSRunningApplication] {
        let runningApps = NSWorkspace.shared.runningApplications

        return runningApps.filter { app in
            guard let bundleID = app.bundleIdentifier else { return false }

            // Don't include Zoomies itself.
            guard bundleID != Bundle.main.bundleIdentifier else { return false }

            // Ignore background agents and system only processes.
            guard app.activationPolicy == .regular else { return false }

            // Skip anything already shutting down.
            guard !app.isTerminated else { return false }

            // The hard safety list we made to protect macOS processes.
            guard !alwaysProtectedBundleIDs.contains(bundleID) else { return false }

            // The user selected apps they want to protect.
            guard !protectedBundleIDs.contains(bundleID) else { return false }

            // Anything that's left is a normal visible app that can be cleaned up safely.
            return true
        }
    }

    // Build a review plan before Zoomies closes anything.
    // This is the big improvement for v1.1, to show a preview and then close if it all looks good.
    func previewCleanup(protectedBundleIDs: Set<String>) -> CleanupResult {
        let candidates = candidateAppsForClosure(protectedBundleIDs: protectedBundleIDs)
        let candidateSnapshots = candidates.map(makeClosedAppSnapshot)

        Logger.log("Preview found \(candidateSnapshots.count) app(s) that can be closed")

        return CleanupResult(
            candidateApps: candidateSnapshots,
            closedApps: [],
            skippedApps: [],
            failedApps: []
        )
    }

    // Close everything that has been marked as safe and not protected by any of the profiles.
    func closeBackgroundApps(protectedBundleIDs: Set<String>) -> CleanupResult {
        let candidates = candidateAppsForClosure(protectedBundleIDs: protectedBundleIDs)

        var result = CleanupResult.empty
        result.candidateApps = candidates.map(makeClosedAppSnapshot)

        for app in candidates {
            let closedApp = makeClosedAppSnapshot(from: app)
            let terminated = app.terminate()

            if terminated {
                Logger.log("Closed app: \(closedApp.name)")
                result.closedApps.append(closedApp)
            } else {
                Logger.log("Failed to close app: \(closedApp.name)")
                result.failedApps.append(closedApp.name)
            }
        }

        return result
    }

    private func makeClosedAppSnapshot(from app: NSRunningApplication) -> ClosedApp {
        let name = app.localizedName ?? "Unknown App"
        let bundleID = app.bundleIdentifier ?? "unknown.bundle.id"

        return ClosedApp(
            name: name,
            bundleID: bundleID,
            bundleURL: app.bundleURL
        )
    }
}
