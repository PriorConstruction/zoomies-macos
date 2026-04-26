//
//  AppDelegate.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// AppKit owns the menu bar item for Zoomies.
// This will give us more control than the MenuBarExtra did.

import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let manager = ZoomiesAppModel.shared.manager
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = StatusBarController(manager: manager)
        statusBarController = controller

        // Before the review window appears - we will close the menu popover.
        // This removes the unneeded "Review Window Open" text.
        manager.onPreviewWillOpen = { [weak controller] in
            controller?.closePopover()
        }

        let hasSeenWelcome = UserDefaults.standard.bool(forKey: AppStorageKeys.hasSeenWelcome)

        if !hasSeenWelcome {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                WelcomeWindowController.showWelcomeWindow()
            }
        }
    }
}
