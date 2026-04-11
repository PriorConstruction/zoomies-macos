//
//  ZoomiesApp.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Main app entry point and to let us run the window/menu bar utility from the same manager.

import SwiftUI
import AppKit

@main
struct ZoomiesApp: App {
    @StateObject private var manager = ZoomiesManager()
    // To show the onboarding just once before going to menu bar utility.
    init() {
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: AppStorageKeys.hasSeenWelcome)

        if !hasSeenWelcome {
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
                NSApp.activate(ignoringOtherApps: true)
                WelcomeWindowController.showWelcomeWindow()
            }
        }
    }
    // The quick access menu so gaming sessions can be started without opening main wndow.
    var body: some Scene {
        MenuBarExtra("Zoomies", systemImage: "gamecontroller.fill") {
            MenuBarView(manager: manager)
        }
    }
}
