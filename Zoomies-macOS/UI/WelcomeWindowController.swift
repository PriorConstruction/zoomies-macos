//
//  WelcomeWindowController.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// To keep the welcome window away from the menu bar app.

import SwiftUI
import AppKit

final class WelcomeWindowController: NSWindowController {
    private static var sharedController: WelcomeWindowController?
    // Open the onboarding window as a first run experience of Zoomies.
    static func showWelcomeWindow() {
        let contentView = WelcomeView {
            UserDefaults.standard.set(true, forKey: AppStorageKeys.hasSeenWelcome)
            UserDefaults.standard.synchronize()
            // Welcome window to be releaased once onboarding completed.
            sharedController?.close()
            sharedController = nil
        }

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.contentViewController = hostingController
        window.title = "Welcome to Zoomies"
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        let controller = WelcomeWindowController(window: window)
        sharedController = controller
        controller.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}
