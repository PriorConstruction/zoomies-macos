//
//  MenuBarView.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Menu bbar interface used for starting, ending and restoring sessions.

import SwiftUI
import AppKit

// To keep the most common actions one click away from the menu bar.
struct MenuBarView: View {
    @ObservedObject var manager: ZoomiesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sessionSection

            Divider()
            // The apps chosen for Zoomies to leave alone during cleanup.
            Menu("Protected Apps") {
                ForEach(manager.protectedApps) { app in
                    Toggle(
                        app.name,
                        isOn: Binding<Bool>(
                            get: {
                                manager.isProtected(app)
                            },
                            set: { newValue in
                                manager.setProtection(for: app, isEnabled: newValue)
                            }
                        )
                    )
                }
            }
            // Used for the session behaviour and system toggles.
            Menu("Options") {
                Toggle(
                    "Offer app restore after session",
                    isOn: Binding<Bool>(
                        get: {
                            manager.options.restoreAppsAfterSession
                        },
                        set: { newValue in
                            manager.options.restoreAppsAfterSession = newValue
                        }
                    )
                )

                Toggle(
                    "Enable Metal HUD",
                    isOn: Binding<Bool>(
                        get: {
                            manager.options.enableMetalHUD
                        },
                        set: { newValue in
                            manager.options.enableMetalHUD = newValue
                        }
                    )
                )

                Toggle(
                    "Enable High Power Mode",
                    isOn: Binding<Bool>(
                        get: {
                            manager.options.enableHighPowerMode
                        },
                        set: { newValue in
                            manager.options.enableHighPowerMode = newValue
                        }
                    )
                )

                Toggle(
                    "Launch at Login",
                    isOn: Binding<Bool>(
                        get: {
                            manager.options.launchAtLogin
                        },
                        set: { newValue in
                            manager.setLaunchAtLogin(newValue)
                        }
                    )
                )
            }
            // The quick presets that will be commonly used. 
            Menu("Profiles") {
                Button {
                    manager.applyStandardProfile()
                } label: {
                    profileMenuLabel("Standard", isSelected: manager.selectedProfile == .standard)
                }

                Button {
                    manager.applySteamProfile()
                } label: {
                    profileMenuLabel("Steam", isSelected: manager.selectedProfile == .steam)
                }

                Button {
                    manager.applyBattleNetProfile()
                } label: {
                    profileMenuLabel("Battle.net", isSelected: manager.selectedProfile == .battleNet)
                }

                Button {
                    manager.applyCrossOverProfile()
                } label: {
                    profileMenuLabel("CrossOver", isSelected: manager.selectedProfile == .crossOver)
                }

                Button {
                    manager.applyParallelsProfile()
                } label: {
                    profileMenuLabel("Parallels", isSelected: manager.selectedProfile == .parallels)
                }
            }

            Divider()

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.65))
            
            Button("Check Releases") {
                if let url = URL(string: "http://www.zoomiesformacos.com") {
                    NSWorkspace.shared.open(url)
                }
            }
#if DEBUG
Button("Reset Welcome Screen") { // Used for testing the onboarding screen.
    UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
    UserDefaults.standard.synchronize()
    NSApplication.shared.terminate(nil)
}
#endif
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 320)
    }
    // The session controls shown first.
    private var sessionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if manager.isSessionActive {
                Label("Gaming Session Active", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text("\(manager.lastCleanupResult.closedApps.count) app(s) closed")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    if manager.options.restoreAppsAfterSession &&
                        !manager.lastCleanupResult.closedApps.isEmpty {
                        manager.restorePreviousApps()
                    } else {
                        manager.endGamingSession()
                    }
                } label: {
                    Label(endSessionButtonTitle, systemImage: "stop.circle")
                }
            } else {
                Button {
                    manager.prepareGamingSession()
                } label: {
                    Label("Prepare for Gaming", systemImage: "gamecontroller.fill")
                }
            }
        }
    }
    // A status summary so the latest session rresult is visible.
    private var statusText: String {
        switch manager.sessionStatus {
        case .ready:
            return "Ready • \(manager.selectedProfile.rawValue) profile selected"
        case .active(let closedCount):
            return "Session active • \(closedCount) app(s) closed"
        case .ended(let closedCount):
            return "Last session ended • \(closedCount) app(s) closed"
        case .restored:
            return "Last session restored • \(manager.selectedProfile.rawValue) profile"
        }
    }
    // Will show just end session if restore toggle is unselected/show restore apps if toggled on.
    private var endSessionButtonTitle: String {
        if manager.options.restoreAppsAfterSession &&
            !manager.lastCleanupResult.closedApps.isEmpty {
            return "End Session & Restore Apps"
        } else {
            return "End Session"
        }
    }
    // This adds the checkmark to the currently selected profile in the menu.
    @ViewBuilder
    private func profileMenuLabel(_ title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
