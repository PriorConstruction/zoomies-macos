//
//  GamingProfile.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The built in gaming profiles that are shown in the UI. 

import Foundation

enum GamingProfile: String, CaseIterable, Codable {
    case standard = "Standard"
    case steam = "Steam"
    case battleNet = "Battle.net"
    case crossOver = "CrossOver"
    case parallels = "Parallels"
}
