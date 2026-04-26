//
//  ZoomiesManager.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The brain of Zoomies - to handle profiles, session states, cleanup and restoring of apps, keeping it all in sync.

import Foundation
import Combine

@MainActor
final class ZoomiesManager: ObservableObject {
    @Published var options: SessionOptions = .default {
        didSet {
            guard !isLoadingState else { return }
            persistState()
        }
    }

    @Published var isSessionActive = false
    @Published var lastCleanupResult: CleanupResult = .empty
    @Published var sessionStatus: SessionStatus = .ready

    // Apps the user has manually added to the protected list.
    // These now belong to the Custom profile so the built in profiles stay clean and predictable.
    @Published var customProtectedApps: [CustomProtectedApp] = []

    // Keep the profile as the one real source of truth.
    // Keeping a second published String copy caused a SwiftUI/AppKit pick loop.
    @Published var selectedProfile: GamingProfile = .standard {
        didSet {
            guard !isLoadingState else { return }
            guard oldValue != selectedProfile else { return }
            applySelectedProfile()
            persistState()
        }
    }

    @Published var previewApps: [ClosedApp] = []
    @Published var transientMessage: String?

    let protectedApps = ProtectedApp.default

    private let cleanupService = ProcessCleanupService()
    private let restoreService = RestoreService()
    private let systemIntegrationService = SystemIntegrationService()
    private let defaults = UserDefaults.standard

    // Stops loadState() from accidentally saving half loaded defaults back over the users saved setup.
    private var isLoadingState = false

    // To track whether Metal HUD was enabled for the session or not.
    private var didEnableMetalHUDForCurrentSession = false

    // Let the status bar controller close the menu before the review window opens.
    var onPreviewWillOpen: (() -> Void)?

    init() {
        loadState()
        options.launchAtLogin = systemIntegrationService.isLaunchAtLoginEnabled()
        systemIntegrationService.restoreManagedStateIfNeeded()
        applySelectedProfile()
        persistState()
    }

    // String version for UI controls and persistence helpers.
    var selectedProfileID: String {
        selectedProfile.rawValue
    }

    // Simple display name for our status rows.
    var selectedProfileDisplayName: String {
        selectedProfile.label
    }

    var hasAppsPendingRestore: Bool {
        !restoreService.recentlyClosedApps.isEmpty
    }

    var canShowHighPowerModeShortcut: Bool {
        systemIntegrationService.isHighPowerModeSupported()
    }

    // An alias for the older and newer views so they both build ok.
    var canShowHighPowerModeToggle: Bool {
        canShowHighPowerModeShortcut
    }

    var canUseLaunchAtLogin: Bool {
        systemIntegrationService.isLaunchAtLoginSupported()
    }

    // The session flow

    // This now opens a preview first so that nothing surprising happens to the users apps and they can confirm before closing.
    func reviewAndPrepareForGaming() {
        Logger.log("Preparing preview for gaming session")

        let result = cleanupService.previewCleanup(protectedBundleIDs: options.protectedBundleIDs)
        previewApps = result.candidateApps
        lastCleanupResult = result
        sessionStatus = .previewing(count: result.candidateApps.count)

        let builtInProtectedApps = protectedApps
            .filter { isProtected($0) }
            .map {
                ProtectedPreviewApp(
                    name: $0.name,
                    bundleIDs: $0.bundleIDs
                )
            }

        let customPreviewApps: [ProtectedPreviewApp]

        if selectedProfile == .custom {
            customPreviewApps = customProtectedApps
                .filter { isCustomProtected($0) }
                .map {
                    ProtectedPreviewApp(
                        name: $0.name,
                        bundleIDs: [$0.bundleID]
                    )
                }
        } else {
            customPreviewApps = []
        }

        let protectedPreviewApps = builtInProtectedApps + customPreviewApps

        // Close the menu first so the next time it opens, it renders in fresh.
        onPreviewWillOpen?()

        PreviewWindowController.showPreviewWindow(
            protectedApps: protectedPreviewApps,
            backgroundApps: result.candidateApps,
            restoreApps: options.restoreAppsAfterSession,
            onRestoreChanged: { [weak self] shouldRestore in
                Task { @MainActor in
                    self?.options.restoreAppsAfterSession = shouldRestore
                }
            },
            onCancel: { [weak self] in
                Task { @MainActor in
                    self?.cancelPreview()
                }
            },
            onPrepare: { [weak self] in
                Task { @MainActor in
                    self?.confirmPreviewAndPrepare()
                }
            }
        )
    }

    // If the review window is closed or cancelled, Zoomies should go back to ready.
    func cancelPreview() {
        if case .previewing = sessionStatus {
            previewApps = []
            lastCleanupResult = .empty
            sessionStatus = .ready
            transientMessage = nil
            Logger.log("Preview cancelled")
        }
    }

    // This is called after the user confirms from the preview window.
    func confirmPreviewAndPrepare() {
        Logger.log("Preview confirmed")
        sessionStatus = .preparing
        prepareGamingSession()
    }

    // This will start the session by closing the unneeded apps and applying our safe session helpers.
    func prepareGamingSession() {
        Logger.log("Preparing gaming session")
        sessionStatus = .preparing

        var messages: [String] = []

        if options.enableMetalHUD {
            systemIntegrationService.setMetalHUDEnabled(true)
            didEnableMetalHUDForCurrentSession = true

            messages.append(
                "Metal HUD enabled for newly launched games. If Steam is already open, fully quit and reopen Steam first."
            )
        } else {
            didEnableMetalHUDForCurrentSession = false
        }

        if options.enableHighPowerModeShortcut {
            systemIntegrationService.openEnergySettings()

            messages.append(
                "High Power Mode is managed in System Settings. Zoomies opened the right place for you."
            )
        }

        transientMessage = messages.isEmpty ? nil : messages.joined(separator: " ")

        let result = cleanupService.closeBackgroundApps(
            protectedBundleIDs: options.protectedBundleIDs
        )

        lastCleanupResult = result
        restoreService.storeClosedApps(result.closedApps)

        isSessionActive = true
        sessionStatus = .active(closedCount: result.closedApps.count)

        Logger.log("Gaming session prepared")
    }

    // For ending the session but to leave restore as a separate action if the user wants that.
    func endGamingSession() {
        Logger.log("Ending gaming session")

        let closedCount = lastCleanupResult.closedApps.count

        if didEnableMetalHUDForCurrentSession {
            systemIntegrationService.setMetalHUDEnabled(false)
            transientMessage =
                "Session ended. \(closedCount) app\(closedCount == 1 ? "" : "s") were closed. Metal HUD cleared. Restart Steam if it is still open."
        } else {
            transientMessage =
                "Session ended. \(closedCount) app\(closedCount == 1 ? "" : "s") were closed."
        }

        didEnableMetalHUDForCurrentSession = false

        isSessionActive = false
        lastCleanupResult = .empty
        previewApps = []
        sessionStatus = .ready
    }

    // To bring back the closed apps and restore the temporary changes that were made.
    func restorePreviousApps() {
        Logger.log("Restoring previous apps")

        let restoredCount = restoreService.restoreApps()

        if didEnableMetalHUDForCurrentSession {
            systemIntegrationService.setMetalHUDEnabled(false)
            transientMessage =
                "\(restoredCount) app\(restoredCount == 1 ? "" : "s") restored. Metal HUD cleared. Restart Steam if it is still open."
        } else {
            transientMessage =
                "\(restoredCount) app\(restoredCount == 1 ? "" : "s") restored."
        }

        didEnableMetalHUDForCurrentSession = false

        isSessionActive = false
        lastCleanupResult = .empty
        previewApps = []

        sessionStatus = .ready

        Logger.log("Restored \(restoredCount) app(s)")
    }

    // Options and profile helpers

    func setLaunchAtLogin(_ enabled: Bool) {
        options.launchAtLogin = enabled
        systemIntegrationService.setLaunchAtLoginEnabled(enabled)
        options.launchAtLogin = systemIntegrationService.isLaunchAtLoginEnabled()
    }

    func openHighPowerModeSettings() {
        systemIntegrationService.openEnergySettings()
    }

    func selectProfile(_ profile: GamingProfile) {
        selectedProfile = profile
    }

    // This lets the String based UI update the real profile safely.
    func selectProfile(id: String) {
        guard let profile = GamingProfile(rawValue: id) else {
            selectProfile(.standard)
            return
        }

        selectProfile(profile)
    }

    // Lets the user manually clear the Metal HUD without needing to start/end their session.
    func disableMetalHUDNow() {
        systemIntegrationService.setMetalHUDEnabled(false)
        Logger.log("Metal Performance HUD manually disabled")
    }

    // Let the UI toggle any grouped protected apps on or off.
    func setProtection(for app: ProtectedApp, isEnabled: Bool) {
        if isEnabled {
            options.protectedBundleIDs.formUnion(app.bundleIDs)
        } else {
            options.protectedBundleIDs.subtract(app.bundleIDs)
        }

        // Changing built in protection is a custom choice, so we move the user into Custom.
        // This keeps Standard, Steam, CrossOver etc clean and untouched.
        if selectedProfile != .custom {
            selectedProfile = .custom
        } else {
            applySelectedProfile()
            persistState()
        }
    }

    func isProtected(_ app: ProtectedApp) -> Bool {
        app.bundleIDs.allSatisfy { options.protectedBundleIDs.contains($0) }
    }

    func clearTransientMessage() {
        transientMessage = nil
    }

    // Adds a user selected app/software to the protected list.
    func addCustomProtectedApp(from appURL: URL) {
        guard let bundle = Bundle(url: appURL),
              let bundleID = bundle.bundleIdentifier else {
            Logger.log("Could not read bundle identifier for selected app")
            return
        }

        let appName = FileManager.default.displayName(atPath: appURL.path)

        let customApp = CustomProtectedApp(
            name: appName.replacingOccurrences(of: ".app", with: ""),
            bundleID: bundleID,
            appURL: appURL
        )

        if !customProtectedApps.contains(where: { $0.bundleID == bundleID }) {
            customProtectedApps.append(customApp)
            Logger.log("Added custom protected app: \(customApp.name)")
        } else {
            Logger.log("Custom protected app already exists: \(customApp.name)")
        }

        // Adding a custom app should create/use the Custom profile.
        // The built in profiles remain unaffected and can still be selected later.
        if selectedProfile != .custom {
            selectedProfile = .custom
        } else {
            applySelectedProfile()
            persistState()
        }

        saveDefaultsImmediately()
    }

    // Removes a user added app/software from the protected list.
    func removeCustomProtectedApp(_ app: CustomProtectedApp) {
        customProtectedApps.removeAll { $0.id == app.id }

        if selectedProfile == .custom {
            applySelectedProfile()
        }

        persistState()

        Logger.log("Removed custom protected app: \(app.name)")
    }

    func isCustomProtected(_ app: CustomProtectedApp) -> Bool {
        selectedProfile == .custom && options.protectedBundleIDs.contains(app.bundleID)
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
            "com.razerzone.rzupdater",
            "com.corsair.iCUE",
            "com.steelseries.GG",
            "com.steelseries.gg"
        ])
    }

    private var customProtectedBundleIDs: Set<String> {
        Set(customProtectedApps.map(\.bundleID))
    }

    // What is happening when each profile is selected.
    private func applySelectedProfile() {
        let preservedLaunchAtLogin = options.launchAtLogin

        switch selectedProfile {
        case .standard:
            options.protectedBundleIDs = baselineProtectedBundleIDs
            options.restoreAppsAfterSession = true
            options.enableMetalHUD = false
            options.enableHighPowerModeShortcut = false
            Logger.log("Applied Standard profile")

        case .steam:
            options.protectedBundleIDs = baselineProtectedBundleIDs.union([
                "com.valvesoftware.steam"
            ])
            options.restoreAppsAfterSession = true
            options.enableMetalHUD = false
            options.enableHighPowerModeShortcut = false
            Logger.log("Applied Steam profile")

        case .battleNet:
            options.protectedBundleIDs = baselineProtectedBundleIDs.union([
                "net.battle.app"
            ])
            options.restoreAppsAfterSession = true
            options.enableMetalHUD = false
            options.enableHighPowerModeShortcut = false
            Logger.log("Applied Battle.net profile")

        case .crossOver:
            options.protectedBundleIDs = baselineProtectedBundleIDs.union([
                "com.codeweavers.CrossOver"
            ])
            options.restoreAppsAfterSession = true
            options.enableMetalHUD = false
            options.enableHighPowerModeShortcut = false
            Logger.log("Applied CrossOver profile")

        case .parallels:
            options.protectedBundleIDs = baselineProtectedBundleIDs.union([
                "com.parallels.desktop",
                "com.parallels.Desktop"
            ])
            options.restoreAppsAfterSession = true
            options.enableMetalHUD = false
            options.enableHighPowerModeShortcut = false
            Logger.log("Applied Parallels profile")

        case .custom:
            options.protectedBundleIDs = baselineProtectedBundleIDs.union(customProtectedBundleIDs)
            options.restoreAppsAfterSession = true
            options.enableMetalHUD = false
            options.enableHighPowerModeShortcut = false
            Logger.log("Applied Custom profile")
        }

        // Keep launch at login when switching profiles.
        options.launchAtLogin = preservedLaunchAtLogin

        if !isSessionActive {
            sessionStatus = .ready
        }
    }

    // Persistence

    private func persistState() {
        do {
            let optionData = try JSONEncoder().encode(options)
            defaults.set(optionData, forKey: AppStorageKeys.sessionOptions)
            defaults.set(selectedProfile.rawValue, forKey: AppStorageKeys.selectedProfile)

            let customData = try JSONEncoder().encode(customProtectedApps)
            defaults.set(customData, forKey: AppStorageKeys.customProtectedApps)

            // This helps tiny menu bar changes survive if the app is quit straight after.
            saveDefaultsImmediately()
        } catch {
            Logger.log("Failed to persist state: \(error.localizedDescription)")
        }
    }

    private func saveDefaultsImmediately() {
        defaults.synchronize()
    }

    private func loadState() {
        isLoadingState = true
        defer { isLoadingState = false }

        if let optionData = defaults.data(forKey: AppStorageKeys.sessionOptions),
           let decodedOptions = try? JSONDecoder().decode(SessionOptions.self, from: optionData) {
            options = decodedOptions
        } else {
            options = .default
        }

        // Load any apps the user has manually added to the protected list.
        if let customData = defaults.data(forKey: AppStorageKeys.customProtectedApps),
           let decodedCustomApps = try? JSONDecoder().decode([CustomProtectedApp].self, from: customData) {
            customProtectedApps = decodedCustomApps
        } else {
            customProtectedApps = []
        }

        if let rawProfile = defaults.string(forKey: AppStorageKeys.selectedProfile),
           let savedProfile = GamingProfile(rawValue: rawProfile) {
            selectedProfile = savedProfile
        } else if !customProtectedApps.isEmpty {
            selectedProfile = .custom
        } else {
            selectedProfile = .standard
        }
    }
}
