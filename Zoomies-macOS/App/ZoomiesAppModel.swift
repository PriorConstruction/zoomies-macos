//
//  ZoomiesAppModel.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Shared app model so the menu bar popover and Settings window can use the same Zoomies brain.

import Foundation

@MainActor
final class ZoomiesAppModel {
    static let shared = ZoomiesAppModel()

    let manager = ZoomiesManager()

    private init() {}
}
