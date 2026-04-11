//
//  SystemIntegrationService.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This for handling the temporary tweaks used during gaming sessions.

import Foundation
import AppKit
import ServiceManagement

final class SystemIntegrationService {
    private var previousMetalHUDEnvironmentValue: String?
    private var didManageMetalHUDForSession = false

    private var previousHighPowerModeValue: Int?
    private var didChangeHighPowerModeForSession = false
    // I'm using launchctl so newly launched Metal games support the HUD.
    func setMetalHUDEnabled(_ enabled: Bool) {
        if enabled {
            let currentValue = runShellCommand("/bin/launchctl", arguments: ["getenv", "MTL_HUD_ENABLED"])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            previousMetalHUDEnvironmentValue = currentValue.isEmpty ? nil : currentValue

            _ = runShellCommand("/bin/launchctl", arguments: ["setenv", "MTL_HUD_ENABLED", "1"])
            didManageMetalHUDForSession = true
            Logger.log("Metal HUD enabled")
        } else {
            guard didManageMetalHUDForSession else { return }

            if let previousValue = previousMetalHUDEnvironmentValue, !previousValue.isEmpty {
                _ = runShellCommand("/bin/launchctl", arguments: ["setenv", "MTL_HUD_ENABLED", previousValue])
            } else {
                _ = runShellCommand("/bin/launchctl", arguments: ["unsetenv", "MTL_HUD_ENABLED"])
            }

            previousMetalHUDEnvironmentValue = nil
            didManageMetalHUDForSession = false
            Logger.log("Metal HUD restored to previous state")
        }
    }
    // High Power Mode is handled so it can be enaebled just for the session.
    func setHighPowerModeEnabled(_ enabled: Bool) {
        if enabled {
            applyHighPowerModeIfNeeded()
        } else {
            restoreHighPowerModeIfNeeded()
        }
    }

    func isHighPowerModeSupported() -> Bool {
        let caps = runShellCommand("/usr/bin/pmset", arguments: ["-g", "cap"]).lowercased()
        return caps.contains("highpowermode")
    }

    func currentHighPowerModeStatusText() -> String {
        guard isHighPowerModeSupported() else {
            return "Not supported on this Mac"
        }

        let currentValue = currentHighPowerModeValue()
        return currentValue == 2 ? "Enabled on this Mac" : "Supported • Currently Off"
    }
    // This will keep the login registration outside of the main maanger.
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

    // A little helper for the shell commands when using Metal and power mode checks.
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
    // This is used only for temporary changes that requires admin approval.
    private func runPrivilegedShellCommand(_ command: String) -> Bool {
        let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
        let scriptSource = "do shell script \"\(escapedCommand)\" with administrator privileges"

        guard let script = NSAppleScript(source: scriptSource) else {
            Logger.log("Failed to create privileged AppleScript")
            return false
        }

        var error: NSDictionary?
        script.executeAndReturnError(&error)

        if let error {
            Logger.log("Privileged command failed: \(error)")
            return false
        }

        return true
    }

    private func isOnACPower() -> Bool {
        let output = runShellCommand("/usr/bin/pmset", arguments: ["-g", "ps"]).lowercased()
        return output.contains("ac power")
    }

    private func currentHighPowerModeValue() -> Int {
        let output = runShellCommand("/usr/bin/pmset", arguments: ["-g"])
        let lines = output.split(separator: "\n")

        for line in lines {
            let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            if cleaned.hasPrefix("powermode") || cleaned.hasPrefix("highpowermode") {
                let parts = cleaned
                    .split(whereSeparator: { $0 == " " || $0 == "\t" })
                    .map(String.init)

                if let last = parts.last, let value = Int(last) {
                    return value
                }
            }
        }

        return 0
    }
    // High Power Mode is only to be enabled if the Mac in question supports & Zoomies is the one turning it on.
    private func applyHighPowerModeIfNeeded() {
        guard isHighPowerModeSupported() else {
            Logger.log("High Power Mode is not supported on this Mac")
            return
        }

        let currentValue = currentHighPowerModeValue()
        previousHighPowerModeValue = currentValue

        // If HPM is already on, Zoomies doesn't own restoring it.
        if currentValue == 2 {
            didChangeHighPowerModeForSession = false
            Logger.log("High Power Mode was already enabled before session")
            return
        }

        let command: String
        if isOnACPower() {
            command = "/usr/bin/pmset -c powermode 2"
        } else {
            command = "/usr/bin/pmset -b powermode 2"
        }

        let success = runPrivilegedShellCommand(command)

        if success {
            didChangeHighPowerModeForSession = true
            Logger.log("High Power Mode enabled for session")
        } else {
            didChangeHighPowerModeForSession = false
            Logger.log("Failed to enable High Power Mode")
        }
    }
    // This will restore the previous power mode if Zoomies is the one that changed it.
    private func restoreHighPowerModeIfNeeded() {
        guard isHighPowerModeSupported() else { return }
        guard didChangeHighPowerModeForSession else { return }
        guard let previousValue = previousHighPowerModeValue else { return }

        let command: String
        if isOnACPower() {
            command = "/usr/bin/pmset -c powermode \(previousValue)"
        } else {
            command = "/usr/bin/pmset -b powermode \(previousValue)"
        }

        let success = runPrivilegedShellCommand(command)

        didChangeHighPowerModeForSession = false
        previousHighPowerModeValue = nil

        if success {
            Logger.log("High Power Mode restored to previous state")
        } else {
            Logger.log("Failed to restore High Power Mode")
        }
    }
}
