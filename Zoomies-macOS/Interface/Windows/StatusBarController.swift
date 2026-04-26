//
//  StatusBarController.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// We keep the popover stable and close it before opening the review window, live refreshing a menu popover while AppKit had another window open was eating into resources/messy.

import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let manager: ZoomiesManager

    init(manager: ZoomiesManager) {
        self.manager = manager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()

        super.init()

        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(
            systemSymbolName: "gamecontroller.fill",
            accessibilityDescription: "Zoomies"
        )
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(togglePopover)
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 340, height: 520)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(manager: manager)
        )
    }

    func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            // To rebuild only when opening so so the menu will always reflect the latest session state.
            popover.contentViewController = NSHostingController(
                rootView: MenuBarView(manager: manager)
            )

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
