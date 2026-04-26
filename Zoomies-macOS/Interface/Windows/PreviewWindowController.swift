//
//  PreviewWindowController.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// This is the review step before Zoomies closes anything, show what will stay open, what may close and let the user back out before closing/the session starts.

import SwiftUI
import AppKit

struct ProtectedPreviewApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIDs: [String]

    init(name: String, bundleIDs: [String]) {
        self.id = name
        self.name = name
        self.bundleIDs = bundleIDs
    }
}

final class PreviewWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: PreviewWindowController?

    private var didPrepare = false
    private var onCancel: (() -> Void)?

    static func showPreviewWindow(
        protectedApps: [ProtectedPreviewApp],
        backgroundApps: [ClosedApp],
        restoreApps: Bool,
        onRestoreChanged: @escaping (Bool) -> Void,
        onCancel: @escaping () -> Void,
        onPrepare: @escaping () -> Void
    ) {
        if let shared {
            shared.close()
            Self.shared = nil
        }

        let view = PreparationPreviewView(
            protectedApps: protectedApps,
            backgroundApps: backgroundApps,
            restoreApps: restoreApps,
            onRestoreChanged: onRestoreChanged,
            onPrepare: {
                Self.shared?.didPrepare = true
                onPrepare()
            }
        )

        let hostingController = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Review Preparation"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 540))
        window.center()
        window.isReleasedWhenClosed = false

        let controller = PreviewWindowController(window: window)
        controller.onCancel = onCancel
        window.delegate = controller

        Self.shared = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func closeWindow() {
        shared?.close()
        shared = nil
    }

    func windowWillClose(_ notification: Notification) {
        if !didPrepare {
            onCancel?()
        }

        Self.shared = nil
    }
}

private struct PreparationPreviewView: View {
    let protectedApps: [ProtectedPreviewApp]
    let backgroundApps: [ClosedApp]
    let restoreApps: Bool
    let onRestoreChanged: (Bool) -> Void
    let onPrepare: () -> Void

    @State private var shouldRestoreApps: Bool

    init(
        protectedApps: [ProtectedPreviewApp],
        backgroundApps: [ClosedApp],
        restoreApps: Bool,
        onRestoreChanged: @escaping (Bool) -> Void,
        onPrepare: @escaping () -> Void
    ) {
        self.protectedApps = protectedApps
        self.backgroundApps = backgroundApps
        self.restoreApps = restoreApps
        self.onRestoreChanged = onRestoreChanged
        self.onPrepare = onPrepare
        _shouldRestoreApps = State(initialValue: restoreApps)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    previewSection(
                        title: "Protected Apps",
                        subtitle: "Will stay open",
                        rows: protectedApps.map {
                            PreviewRow(
                                title: $0.name,
                                bundleIdentifiers: $0.bundleIDs,
                                bundleIdentifier: nil
                            )
                        },
                        emptyText: "No protected apps detected"
                    )

                    previewSection(
                        title: "Background Apps",
                        subtitle: "Will close",
                        rows: backgroundApps.map {
                            PreviewRow(
                                title: $0.name,
                                bundleIdentifiers: [$0.bundleID],
                                bundleIdentifier: $0.bundleID
                            )
                        },
                        emptyText: "Nothing to close"
                    )
                }
                .padding(16)
            }

            Divider()

            footerSection
                .padding(14)
        }
        .frame(width: 500, height: 540)
        .background(.regularMaterial)
    }

    // Heading section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Review & Prepare for Gaming")
                .font(.title3.weight(.semibold))

            Text("Zoomies will only ask normal background apps to close. Any protected apps will remain open and nothing will happen until you press Prepare.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // App sections

    private func previewSection(
        title: String,
        subtitle: String,
        rows: [PreviewRow],
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.headline)

                Text("(\(subtitle))")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 0) {
                if rows.isEmpty {
                    PreviewEmptyRow(title: emptyText)
                } else {
                    ForEach(rows) { row in
                        PreviewAppRow(row: row)

                        if row.id != rows.last?.id {
                            Divider()
                                .padding(.leading, 38)
                        }
                    }
                }
            }
            .background(.background.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // Footer section

    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Restore these apps after the session", isOn: $shouldRestoreApps)
                .onChange(of: shouldRestoreApps) { newValue in
                    onRestoreChanged(newValue)
                }

            HStack {
                Button("Cancel") {
                    PreviewWindowController.closeWindow()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Prepare") {
                    onPrepare()
                    PreviewWindowController.closeWindow()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// The rows

private struct PreviewRow: Identifiable {
    let id = UUID()
    let title: String
    let bundleIdentifiers: [String]
    let bundleIdentifier: String?
}

private struct PreviewAppRow: View {
    let row: PreviewRow

    var body: some View {
        HStack(spacing: 10) {
            appIcon
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(row.title)

                if let bundleIdentifier = row.bundleIdentifier, !bundleIdentifier.isEmpty {
                    Text(bundleIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    // We will try to use the real macOS app icon first.
    // If macOS cannot find it, will fall back to a plain application icon.
    private var appIcon: some View {
        Image(nsImage: AppIconResolver.icon(bundleIdentifiers: row.bundleIdentifiers, appName: row.title))
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

private struct PreviewEmptyRow: View {
    let title: String

    var body: some View {
        Text(title)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// App icon helper

private enum AppIconResolver {
    static func icon(bundleIdentifiers: [String], appName: String) -> NSImage {
        // First try the bundle IDs, because this is the cleanest way when LaunchServices knows the app.
        for bundleIdentifier in bundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }

        // If the app is currently running, use that app bundle directly.
        // This helps with apps that LaunchServices does not always resolve nicely.
        for runningApp in NSWorkspace.shared.runningApplications {
            if let bundleIdentifier = runningApp.bundleIdentifier,
               bundleIdentifiers.contains(bundleIdentifier),
               let bundleURL = runningApp.bundleURL {
                return NSWorkspace.shared.icon(forFile: bundleURL.path)
            }
        }

        // Try the friendly app name and any known real .app names we know about.
        for candidateName in candidateAppNames(for: appName, bundleIdentifiers: bundleIdentifiers) {
            if let appURL = findApplicationURL(named: candidateName) {
                return NSWorkspace.shared.icon(forFile: appURL.path)
            }
        }

        // Last fallback so the UI never looks broken.
        return NSWorkspace.shared.icon(forFileType: "app")
    }

    private static func candidateAppNames(for appName: String, bundleIdentifiers: [String]) -> [String] {
        var names: [String] = [
            appName,
            "\(appName).app"
        ]

        // Some gaming apps have public names that do not match their app bundle name exactly.
        if appName == "Steam" || bundleIdentifiers.contains("com.valvesoftware.steam") {
            names.append(contentsOf: [
                "Steam",
                "Steam.app"
            ])
        }

        if appName == "Battle.net" || bundleIdentifiers.contains("net.battle.app") {
            names.append(contentsOf: [
                "Battle.net",
                "Battle.net.app",
                "Battle.net Launcher",
                "Battle.net Launcher.app"
            ])
        }

        if appName == "CrossOver" || bundleIdentifiers.contains("com.codeweavers.CrossOver") {
            names.append(contentsOf: [
                "CrossOver",
                "CrossOver.app",
                "CodeWeavers CrossOver",
                "CodeWeavers CrossOver.app"
            ])
        }

        if appName == "Parallels" ||
            appName == "Parallels Desktop" ||
            bundleIdentifiers.contains("com.parallels.desktop") ||
            bundleIdentifiers.contains("com.parallels.Desktop") {
            names.append(contentsOf: [
                "Parallels Desktop",
                "Parallels Desktop.app",
                "Parallels",
                "Parallels.app"
            ])
        }

        if appName == "Gaming Peripheral Software" {
            names.append(contentsOf: [
                "Logi G HUB",
                "Logi G HUB.app",
                "Logitech G HUB",
                "Logitech G HUB.app",
                "G HUB",
                "G HUB.app",
                "Corsair iCUE",
                "Corsair iCUE.app",
                "iCUE",
                "iCUE.app",
                "SteelSeries GG",
                "SteelSeries GG.app",
                "Razer Synapse",
                "Razer Synapse.app"
            ])
        }

        // Bundle IDs can also tell us which icon to prefer.
        if bundleIdentifiers.contains("com.logi.ghub") {
            names.append(contentsOf: [
                "Logi G HUB",
                "Logi G HUB.app",
                "Logitech G HUB",
                "Logitech G HUB.app",
                "G HUB",
                "G HUB.app"
            ])
        }

        if bundleIdentifiers.contains("com.corsair.iCUE") {
            names.append(contentsOf: [
                "Corsair iCUE",
                "Corsair iCUE.app",
                "iCUE",
                "iCUE.app"
            ])
        }

        if bundleIdentifiers.contains("com.steelseries.GG") ||
            bundleIdentifiers.contains("com.steelseries.gg") {
            names.append(contentsOf: [
                "SteelSeries GG",
                "SteelSeries GG.app"
            ])
        }

        return Array(NSOrderedSet(array: names)) as? [String] ?? names
    }

    private static func findApplicationURL(named appName: String) -> URL? {
        let fileManager = FileManager.default

        let candidateNames: [String]

        if appName.hasSuffix(".app") {
            candidateNames = [appName]
        } else {
            candidateNames = [
                appName,
                "\(appName).app"
            ]
        }

        let searchFolders = [
            "/Applications",
            "/System/Applications",
            "\(NSHomeDirectory())/Applications"
        ]

        for folder in searchFolders {
            for candidateName in candidateNames {
                let url = URL(fileURLWithPath: folder).appendingPathComponent(candidateName)

                if fileManager.fileExists(atPath: url.path) {
                    return url
                }
            }
        }

        return nil
    }
}
