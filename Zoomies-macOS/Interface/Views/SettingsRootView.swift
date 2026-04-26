//
//  SettingsRootView.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Unified settings for Zoomies and the menu stays lightweight, our configuration lives here like a proper Mac utility.

import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

enum SettingsTab {
    case general
    case protectedApps
}

@MainActor
final class SettingsSelectionState: ObservableObject {
    @Published var selectedTab: SettingsTab = .general
}

struct SettingsRootView: View {
    @ObservedObject var manager: ZoomiesManager
    @ObservedObject var settingsState: SettingsSelectionState

    var body: some View {
        Group {
            switch settingsState.selectedTab {
            case .general:
                GeneralSettingsPane(manager: manager)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                    .frame(width: 520, height: 420)

            case .protectedApps:
                ProtectedAppsSettingsPane(manager: manager)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 18)
                    .frame(width: 520, height: 420)
            }
        }
    }
}

// Settings

private struct GeneralSettingsPane: View {
    @ObservedObject var manager: ZoomiesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            PreferenceSectionHeader(
                title: "Session",
                subtitle: "Choose how Zoomies behaves when preparing and ending a gaming session."
            )

            PreferenceToggleRow(
                title: "Offer app restore after session",
                subtitle: "Offer to reopen apps Zoomies closed once your session is finished.",
                isOn: Binding(
                    get: { manager.options.restoreAppsAfterSession },
                    set: { manager.options.restoreAppsAfterSession = $0 }
                )
            )

            Divider()

            PreferenceSectionHeader(
                title: "Performance",
                subtitle: "Optional macOS performance features available on supported Macs."
            )

            if manager.canShowHighPowerModeShortcut {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("High Power Mode")

                        Text("Controlled by macOS. Open the relevant System Settings page.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    Button("Open Settings…") {
                        manager.openHighPowerModeSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(minHeight: 38)
            } else {
                Text("High Power Mode is not available on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            PreferenceSectionHeader(
                title: "Advanced",
                subtitle: "Optional tools for diagnostics, benchmarking and performance testing."
            )

            PreferenceToggleRow(
                title: "Enable Metal Performance HUD",
                subtitle: "Shows Apple’s Metal overlay for supported games launched after preparation. You may need to relaunch Steam, CrossOver or the game after starting a Zoomies session.",
                isOn: Binding(
                    get: { manager.options.enableMetalHUD },
                    set: { manager.options.enableMetalHUD = $0 }
                )
            )

            HStack {
                Spacer()

                Button("Turn Off Metal HUD Now") {
                    manager.disableMetalHUDNow()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Divider()

            PreferenceSectionHeader(
                title: "Startup",
                subtitle: "Control whether Zoomies starts quietly in the menu bar."
            )

            if manager.canUseLaunchAtLogin {
                PreferenceToggleRow(
                    title: "Launch at Login",
                    subtitle: "Start Zoomies when you sign in.",
                    isOn: Binding(
                        get: { manager.options.launchAtLogin },
                        set: { manager.setLaunchAtLogin($0) }
                    )
                )
            } else {
                Text("Launch at Login is not available on this macOS version.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: 490, alignment: .topLeading)
    }
}

// Protected apps

private struct ProtectedAppsSettingsPane: View {
    @ObservedObject var manager: ZoomiesManager

    @State private var selectedCustomAppID: CustomProtectedApp.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreferenceSectionHeader(
                title: "Protected Apps",
                subtitle: "Custom apps are saved to your Custom profile. The built in profiles stay clean and untouched."
            )

            VStack(spacing: 0) {
                List(selection: $selectedCustomAppID) {
                    Section("Built-in Protected Apps") {
                        ForEach(manager.protectedApps) { app in
                            BuiltInProtectedAppRow(
                                app: app,
                                isProtected: Binding(
                                    get: { manager.isProtected(app) },
                                    set: { manager.setProtection(for: app, isEnabled: $0) }
                                )
                            )
                        }
                    }

                    Section("Custom Protected Apps") {
                        if manager.customProtectedApps.isEmpty {
                            EmptyCustomAppsRow()
                        } else {
                            ForEach(manager.customProtectedApps) { app in
                                CustomProtectedAppRow(app: app)
                                    .tag(app.id)
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .frame(height: 295)

                Divider()

                HStack(spacing: 0) {
                    Button {
                        addCustomApp()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 24, height: 20)
                    }
                    .buttonStyle(.borderless)
                    .help("Add an app to your Custom profile")

                    Divider()
                        .frame(height: 20)

                    Button {
                        removeSelectedCustomApp()
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 24, height: 20)
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedCustomAppID == nil)
                    .help("Remove selected custom app")

                    Spacer()

                    Text("Adding apps switches Zoomies to Custom.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.22))
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(.separator, lineWidth: 1)
            }
        }
        .frame(width: 470, height: 320, alignment: .topLeading)
    }

    // App selector

    private func addCustomApp() {
        let panel = NSOpenPanel()
        panel.title = "Choose an app to protect"
        panel.message = "Zoomies will add this app to your Custom profile and keep it open during gaming sessions."
        panel.prompt = "Add"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.applicationBundle]

        if panel.runModal() == .OK, let url = panel.url {
            manager.addCustomProtectedApp(from: url)
        }
    }

    private func removeSelectedCustomApp() {
        guard let selectedCustomAppID,
              let app = manager.customProtectedApps.first(where: { $0.id == selectedCustomAppID }) else {
            return
        }

        manager.removeCustomProtectedApp(app)
        self.selectedCustomAppID = nil
    }
}

// Shared settings

private struct PreferenceSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PreferenceToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.checkbox)
        }
        .frame(minHeight: 38)
    }
}

// Protected app rows

private struct BuiltInProtectedAppRow: View {
    let app: ProtectedApp
    @Binding var isProtected: Bool

    var body: some View {
        HStack(spacing: 10) {
            AppIconView(
                bundleIdentifiers: app.bundleIDs,
                appName: app.name
            )

            Text(app.name)

            Spacer(minLength: 12)

            Toggle("", isOn: $isProtected)
                .labelsHidden()
                .toggleStyle(.checkbox)
        }
        .padding(.vertical, 2)
    }
}

private struct CustomProtectedAppRow: View {
    let app: CustomProtectedApp

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.appURL.path))
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)

                Text(app.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 12)
        }
        .padding(.vertical, 2)
    }
}

private struct EmptyCustomAppsRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .opacity(0.45)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("No custom apps yet")

                Text("Use + to add apps to your Custom profile.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 2)
    }
}

// App icon helper

private struct AppIconView: View {
    let bundleIdentifiers: [String]
    let appName: String

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
    }

    private var icon: NSImage {
        AppIconResolver.icon(
            bundleIdentifiers: bundleIdentifiers,
            appName: appName
        )
    }
}

private enum AppIconResolver {
    static func icon(bundleIdentifiers: [String], appName: String) -> NSImage {
        // First try the bundle IDs because this is the cleanest way when LaunchServices knows the app.
        for bundleIdentifier in bundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }

        // If the app is currently running - use that app bundle directly.
        // This helps with apps that LaunchServices does not always resolve.
        for runningApp in NSWorkspace.shared.runningApplications {
            if let bundleIdentifier = runningApp.bundleIdentifier,
               bundleIdentifiers.contains(bundleIdentifier),
               let bundleURL = runningApp.bundleURL {
                return NSWorkspace.shared.icon(forFile: bundleURL.path)
            }
        }

        // Try friendly app name and any known real app names we know about.
        for candidateName in candidateAppNames(for: appName, bundleIdentifiers: bundleIdentifiers) {
            if let appURL = findApplicationURL(named: candidateName) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }

        // Last fallback so the UI shouldn't look broken.
        return NSImage(named: NSImage.applicationIconName) ?? NSImage()
    }

    private static func candidateAppNames(for appName: String, bundleIdentifiers: [String]) -> [String] {
        var names: [String] = [
            appName,
            "\(appName).app"
        ]

        // Some gaming apps have public names that do not seem to match the app bundle name exactly.
        if appName == "Steam" || bundleIdentifiers.contains("com.valvesoftware.steam") {
            names.append(contentsOf: [
                "Steam",
                "Steam.app"
            ])
        }

        if appName == "Battle.net" || bundleIdentifiers.contains("net.battle.app") {
            names.append(contentsOf: [
                "Battle.net",
                "Battle.net.app",
                "Battle.net Launcher",
                "Battle.net Launcher.app"
            ])
        }

        if appName == "CrossOver" || bundleIdentifiers.contains("com.codeweavers.CrossOver") {
            names.append(contentsOf: [
                "CrossOver",
                "CrossOver.app",
                "CodeWeavers CrossOver",
                "CodeWeavers CrossOver.app"
            ])
        }

        if appName == "Parallels" ||
            appName == "Parallels Desktop" ||
            bundleIdentifiers.contains("com.parallels.desktop") ||
            bundleIdentifiers.contains("com.parallels.Desktop") {
            names.append(contentsOf: [
                "Parallels Desktop",
                "Parallels Desktop.app",
                "Parallels",
                "Parallels.app"
            ])
        }

        if appName == "Gaming Peripheral Software" {
            names.append(contentsOf: [
                "Logi G HUB",
                "Logi G HUB.app",
                "Logitech G HUB",
                "Logitech G HUB.app",
                "G HUB",
                "G HUB.app",
                "Corsair iCUE",
                "Corsair iCUE.app",
                "iCUE",
                "iCUE.app",
                "SteelSeries GG",
                "SteelSeries GG.app",
                "Razer Synapse",
                "Razer Synapse.app"
            ])
        }

        // The bundle IDs can also tell which icon to prefer.
        if bundleIdentifiers.contains("com.logi.ghub") {
            names.append(contentsOf: [
                "Logi G HUB",
                "Logi G HUB.app",
                "Logitech G HUB",
                "Logitech G HUB.app",
                "G HUB",
                "G HUB.app"
            ])
        }

        if bundleIdentifiers.contains("com.corsair.iCUE") {
            names.append(contentsOf: [
                "Corsair iCUE",
                "Corsair iCUE.app",
                "iCUE",
                "iCUE.app"
            ])
        }

        if bundleIdentifiers.contains("com.steelseries.GG") ||
            bundleIdentifiers.contains("com.steelseries.gg") {
            names.append(contentsOf: [
                "SteelSeries GG",
                "SteelSeries GG.app"
            ])
        }

        return Array(NSOrderedSet(array: names)) as? [String] ?? names
    }

    private static func findApplicationURL(named appName: String) -> URL? {
        let fileManager = FileManager.default

        let candidateNames: [String]

        if appName.hasSuffix(".app") {
            candidateNames = [appName]
        } else {
            candidateNames = [
                appName,
                "\(appName).app"
            ]
        }

        let searchFolders = [
            "/Applications",
            "/System/Applications",
            "\(NSHomeDirectory())/Applications"
        ]

        for folder in searchFolders {
            for candidateName in candidateNames {
                let url = URL(fileURLWithPath: folder).appendingPathComponent(candidateName)

                if fileManager.fileExists(atPath: url.path) {
                    return url
                }
            }
        }

        return nil
    }
}
