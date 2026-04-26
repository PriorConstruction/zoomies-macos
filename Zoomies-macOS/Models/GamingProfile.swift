//
//  GamingProfile.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The built in gaming profiles that are shown in the UI.
// Kept intentionally small so Zoomies feels like a Mac utility and not a giant settings app.

import Foundation

enum GamingProfile: String, CaseIterable, Codable, Identifiable, Equatable, Hashable {
    case standard = "Standard"
    case steam = "Steam"
    case battleNet = "Battle.net"
    case crossOver = "CrossOver"
    case parallels = "Parallels"

    // Custom is the user remembered protection setup.
    // The built in profiles stay clean and predictable and Custom keeps the users own apps separate.
    case custom = "Custom"

    var id: String { rawValue }
    var label: String { rawValue }

    // A small explanation for the profile picker window.
    // Tried to keep it easy to understand.
    var description: String {
        switch self {
        case .standard:
            return "Balanced defaults for most sessions."
        case .steam:
            return "Keeps Steam open while Zoomies prepares your Mac."
        case .battleNet:
            return "Keeps Battle.net open while Zoomies prepares your Mac."
        case .crossOver:
            return "Keeps CrossOver open for Windows games on macOS."
        case .parallels:
            return "Keeps Parallels open for virtual machines and streamed sessions."
        case .custom:
            return "Uses your saved custom protected apps."
        }
    }
}
