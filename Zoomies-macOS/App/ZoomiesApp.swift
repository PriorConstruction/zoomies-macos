//
//  ZoomiesApp.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//


// Main app entry point.
// AppKit now owns the menu bar item and the custom Zoomies Settings window.

import SwiftUI
import AppKit

@main
struct ZoomiesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
