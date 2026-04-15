//
//  ProtectedApp.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// These are the app groups that peole can choose to keep open, this keeps it simple and avoids loads of toggles.

import Foundation

struct ProtectedApp: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let bundleIDs: [String]
    let isEnabledByDefault: Bool

    init(name: String, bundleIDs: [String], isEnabledByDefault: Bool = true) {
        self.id = name
        self.name = name
        self.bundleIDs = bundleIDs
        self.isEnabledByDefault = isEnabledByDefault
    }
}
// One user faced protection group that can map to the difference app IDs.
extension ProtectedApp {
    static let `default`: [ProtectedApp] = [
        
        // The sensible defaults that people will want left alone during gaming.
        ProtectedApp(
            name: "Steam", // Keep Steam open for native games.
            bundleIDs: ["com.valvesoftware.steam"],
            isEnabledByDefault: false
        ),
        ProtectedApp(
            name: "Battle.net", // Keep Battle.net open for native games.
            bundleIDs: ["net.battle.app"],
            isEnabledByDefault: false
        ),
        ProtectedApp(
            name: "CrossOver", // Stay open for playing non-native Mac games.
            bundleIDs: ["com.codeweavers.CrossOver"],
            isEnabledByDefault: false
        ),
        ProtectedApp(
            name: "Parallels", // Keep open for playing non-native Mac games.
            bundleIDs: ["com.parallels.desktop"],
            isEnabledByDefault: false
        ),
            ProtectedApp(
                name: "Discord", // Voice chat should stay open.
                bundleIDs: ["com.hnc.Discord"]
        ),
            ProtectedApp(
                name: "OBS", // Recording/streaming tool often used by gamers.
                bundleIDs: ["com.obsproject.obs-studio"]
        ),
            ProtectedApp(
                name: "Gaming Peripheral Software", // Gaming peripheral protection for Mouse/Keyboard + Elgato.
                bundleIDs: [
                    "com.logi.ghub",
                    "com.razerzone.rzupdater",
                    "com.razer.rzupdater",
                    "com.steelseries.gg",
                    "com.corsair.iCUE",
                    "com.elgato.StreamDeck",
                    "com.elgato.WaveLink"

                ]
            ),
    ]
}
