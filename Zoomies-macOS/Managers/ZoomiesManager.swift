//
//  ZoomiesManager.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The brain of Zoomies - to handle profiles, session states, cleanup and restoring of apps, keep it all in sync.

import Foundation
import Combine

@MainActor
final class ZoomiesManager: ObservableObject {
    @Published var options: SessionOptions = .default
    @Published var isSessionActive = false
    @Published var lastCleanupResult: CleanupResult = .empty
    @Published var sessionStatus: SessionStatus = .ready
    @Published var selectedProfile: GamingProfile = .standard
    
    let protectedApps = ProtectedApp.default
    
    private let cleanupService = ProcessCleanupService()
    private let restoreService = RestoreService()
    private let systemIntegrationService = SystemIntegrationService()
    
    init() {
        options.launchAtLogin = systemIntegrationService.isLaunchAtLoginEnabled()
    }
    
    func setLaunchAtLogin(_ enabled: Bool) {
        options.launchAtLogin = enabled
        systemIntegrationService.setLaunchAtLoginEnabled(enabled)
        
    }
    // This will start the session by closing the unneeded apps and applying the tweaks.
    func prepareGamingSession() {
        Logger.log("Preparing gaming session")
        
        if options.enableMetalHUD {
            systemIntegrationService.setMetalHUDEnabled(true)
        }
        
        if options.enableHighPowerMode {
            systemIntegrationService.setHighPowerModeEnabled(true)
        }
        
        let result = cleanupService.closeBackgroundApps(
            protectedBundleIDs: options.protectedBundleIDs
        )
        
        lastCleanupResult = result
        restoreService.storeClosedApps(result.closedApps)
        isSessionActive = true
        sessionStatus = .active(closedCount: result.closedApps.count)
        
        Logger.log("Gaming session prepared")
    }
    // For ending the session but to leave restore as a separate action.
    func endGamingSession() {
        Logger.log("Ending gaming session")
        
        if options.enableMetalHUD {
            systemIntegrationService.setMetalHUDEnabled(false)
        }
        
        systemIntegrationService.setHighPowerModeEnabled(false)
        
        isSessionActive = false
        sessionStatus = .ended(closedCount: lastCleanupResult.closedApps.count)
    }
    // To bring back the closed apps and restore the temporary changes that were made.
    func restorePreviousApps() {
        Logger.log("Restoring previous apps")
        
        restoreService.restoreApps()
        
        if options.enableMetalHUD {
            systemIntegrationService.setMetalHUDEnabled(false)
        }
        
        systemIntegrationService.setHighPowerModeEnabled(false)
        
        isSessionActive = false
        sessionStatus = .restored
    }
    // Let the UI toggle any grouped protect apps on or off.
    func setProtection(for app: ProtectedApp, isEnabled: Bool) {
        if isEnabled {
            options.protectedBundleIDs.formUnion(app.bundleIDs)
        } else {
            options.protectedBundleIDs.subtract(app.bundleIDs)
        }
    }
    
    func isProtected(_ app: ProtectedApp) -> Bool {
        app.bundleIDs.allSatisfy { options.protectedBundleIDs.contains($0) }
    }
    
    // These are to be protected by the profile selected as default.
    private var baselineProtectedBundleIDs: Set<String> {
        Set([
            // Discord
            "com.hnc.Discord",

            // Common recording/streaming apps
            "com.obsproject.obs-studio",
            "com.elgato.StreamDeck",
            "com.elgato.WaveLink",

            // Gaming peripheral software
            "com.logi.ghub",
            "com.razer.rzupdater",
            "com.corsair.iCUE",
            "com.steelseries.GG",
            
        ])
    }
    
    // What is happening when each profile is selected.
    
    func applyStandardProfile() {
        selectedProfile = .standard
        options.protectedBundleIDs = baselineProtectedBundleIDs
        options.restoreAppsAfterSession = true
        options.enableMetalHUD = false
        options.enableHighPowerMode = false
        Logger.log("Applied Standard profile")
    }
    
    func applySteamProfile() {
        selectedProfile = .steam
        options.protectedBundleIDs = baselineProtectedBundleIDs.union([
            "com.valvesoftware.steam"
        ])
        options.restoreAppsAfterSession = true
        options.enableMetalHUD = false
        options.enableHighPowerMode = false
        Logger.log("Applied Steam profile")
    }
    
    func applyBattleNetProfile() {
        selectedProfile = .battleNet
        options.protectedBundleIDs = baselineProtectedBundleIDs.union([
            "net.battle.app"
        ])
        options.restoreAppsAfterSession = true
        options.enableMetalHUD = false
        options.enableHighPowerMode = false
        Logger.log("Applied Battle.net profile")
    }
    
    func applyCrossOverProfile() {
        selectedProfile = .crossOver
        options.protectedBundleIDs = baselineProtectedBundleIDs.union([
            "com.codeweavers.CrossOver"
        ])
        options.restoreAppsAfterSession = true
        options.enableMetalHUD = false
        options.enableHighPowerMode = false
        Logger.log("Applied CrossOver profile")
    }
    func applyParallelsProfile() {
        selectedProfile = .parallels
        options.protectedBundleIDs = baselineProtectedBundleIDs.union([
            "com.parallels.desktop"
        ])
        options.restoreAppsAfterSession = true
        options.enableMetalHUD = false
        options.enableHighPowerMode = false
        Logger.log("Applied Parallels profile")
    }
}
