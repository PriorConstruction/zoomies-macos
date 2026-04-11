//
//  SettingsView.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The extra settings and controls that don't need to be in the menu bar.

import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: ZoomiesManager
    // Let the user choose which apps they want to stay during cleanup.
    var body: some View {
        Form {
            Section("Protected Apps") {
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
            // The session behaviour/optional tweaks during start of session.
            Section("Options") {
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
            // The summary of what happened during the most recent session.
            Section("Last Session") {
                Text("Closed apps: \(manager.lastCleanupResult.closedApps.count)")
                Text("Failed apps: \(manager.lastCleanupResult.failedApps.count)")
                Text("Profile: \(manager.selectedProfile.rawValue)")
            }
        }
        .padding()
        .frame(width: 420, height: 320)
    }
}
