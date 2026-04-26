//
//  SettingsWindowController.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Unified settings window for Zoomies and everything can live in one place and is lightweight.

import SwiftUI
import AppKit
import Combine

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate, NSToolbarDelegate {
    private static var shared: SettingsWindowController?

    private let settingsState: SettingsSelectionState

    private static let generalToolbarID = NSToolbarItem.Identifier("general")
    private static let protectedAppsToolbarID = NSToolbarItem.Identifier("protectedApps")

    static func show(manager: ZoomiesManager) {
        if let shared {
            shared.showWindow(nil)
            shared.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsState = SettingsSelectionState()
        let view = SettingsRootView(manager: manager, settingsState: settingsState)
        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Zoomies Settings"
        window.titleVisibility = .hidden
        window.toolbarStyle = .preference
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 520, height: 420))
        window.minSize = NSSize(width: 520, height: 420)
        window.center()
        window.isReleasedWhenClosed = false

        let controller = SettingsWindowController(
            window: window,
            settingsState: settingsState
        )

        window.delegate = controller
        window.toolbar = controller.makeToolbar()

        shared = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private init(window: NSWindow, settingsState: SettingsSelectionState) {
        self.settingsState = settingsState
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "SettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        toolbar.selectedItemIdentifier = Self.generalToolbarID
        return toolbar
    }

    func windowWillClose(_ notification: Notification) {
        Self.shared = nil
    }

    // The toolbar actions

    @objc private func showGeneralSettings() {
        settingsState.selectedTab = .general
        window?.toolbar?.selectedItemIdentifier = Self.generalToolbarID
    }

    @objc private func showProtectedAppsSettings() {
        settingsState.selectedTab = .protectedApps
        window?.toolbar?.selectedItemIdentifier = Self.protectedAppsToolbarID
    }

    // NSToolbar 

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            Self.generalToolbarID,
            Self.protectedAppsToolbarID
        ]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            Self.generalToolbarID,
            Self.protectedAppsToolbarID
        ]
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            Self.generalToolbarID,
            Self.protectedAppsToolbarID
        ]
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case Self.generalToolbarID:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "General"
            item.paletteLabel = "General"
            item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")
            item.target = self
            item.action = #selector(showGeneralSettings)
            return item

        case Self.protectedAppsToolbarID:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Protected Apps"
            item.paletteLabel = "Protected Apps"
            item.image = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Protected Apps")
            item.target = self
            item.action = #selector(showProtectedAppsSettings)
            return item

        default:
            return nil
        }
    }
}
