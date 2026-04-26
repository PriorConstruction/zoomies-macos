//
//  SystemIntegrationService.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This handles the small macOS integrations used by Zoomies.
// v1.1 deliberately avoids admin password power tweaks because it took longer than doing it from the built in system settings.

import Foundation
import AppKit
import ServiceManagement

final class SystemIntegrationService {
    // Enables or disables Apple's Metal Performance HUD for games launched after starting Zoomies.
    // This is useful for testing/benchmarking but it will only affects newly launched Metal games.
    func setMetalHUDEnabled(_ enabled: Bool) {
        if enabled {
            runLaunchctl(arguments: ["setenv", "MTL_HUD_ENABLED", "1"])
            runLaunchctl(arguments: ["setenv", "MTL_HUD_INSIGHTS_ENABLED", "1"])
            Logger.log("Metal Performance HUD enabled for newly launched apps")
        } else {
            runLaunchctl(arguments: ["unsetenv", "MTL_HUD_ENABLED"])
            runLaunchctl(arguments: ["unsetenv", "MTL_HUD_INSIGHTS_ENABLED"])
            Logger.log("Metal Performance HUD disabled")
        }
    }

    // Small helper for launchctl commands.
    private func runLaunchctl(arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus != 0 {
                Logger.log("launchctl failed with status \(process.terminationStatus): \(arguments.joined(separator: " "))")
            }
        } catch {
            Logger.log("Failed to run launchctl \(arguments.joined(separator: " ")): \(error.localizedDescription)")
        }
    }
    func isHighPowerModeSupported() -> Bool {
        let caps = runShellCommand("/usr/bin/pmset", arguments: ["-g", "cap"]).lowercased()
        return caps.contains("highpowermode")
    }

    // We open settings rather than asking for an admin password.
    // This keeps Zoomies honest, macOS owns this setting, Zoomies just guides the user there, much quicker to enable this way.
    func openEnergySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.Battery-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.energysaver"
        ]

        for urlString in urls {
            if let url = URL(string: urlString), NSWorkspace.shared.open(url) {
                Logger.log("Opened energy settings")
                return
            }
        }

        Logger.log("Could not open energy settings")
    }

    func restoreManagedStateIfNeeded() {
        // Kept for any future crash recovery hooks.
        // v1.1 does not leave admin power tweaks or global HUD changes behind.
    }

    func isLaunchAtLoginSupported() -> Bool {
        if #available(macOS 13.0, *) {
            return true
        } else {
            return false
        }
    }

    // This will keep the login registration outside of our main manager.
    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else {
            Logger.log("Launch at Login requires macOS 13 or later")
            return
        }

        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                    Logger.log("Launch at Login enabled")
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    Logger.log("Launch at Login disabled")
                }
            }
        } catch {
            Logger.log("Failed to update Launch at Login: \(error.localizedDescription)")
        }
    }

    func isLaunchAtLoginEnabled() -> Bool {
        guard #available(macOS 13.0, *) else {
            return false
        }

        return SMAppService.mainApp.status == .enabled
    }

    private func runShellCommand(_ launchPath: String, arguments: [String]) -> String {
        guard FileManager.default.fileExists(atPath: launchPath) else {
            Logger.log("Missing executable at \(launchPath)")
            return ""
        }

        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            Logger.log("Failed to start shell command \(launchPath): \(error.localizedDescription)")
            return ""
        }

        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorText = String(data: errorData, encoding: .utf8) ?? ""
            Logger.log("Command failed (\(process.terminationStatus)): \(launchPath) \(arguments.joined(separator: " "))")
            if !errorText.isEmpty {
                Logger.log("stderr: \(errorText)")
            }
        }

        return String(data: outputData, encoding: .utf8) ?? ""
    }
}
