//
//  MenuBarView.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// Main menu bar popover for Zoomies.
// Kept deliberately small, start/end sessions here and settings live in their own menu.

import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var manager: ZoomiesManager

    // Local picker state will avoid SwiftUI/AppKit menu loops.
    // The manager is still the real source of truth.
    @State private var pickerProfile: GamingProfile = .standard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            primaryActionSection

            Divider()

            profileSection

            statusSection

            Divider()

            footerSection
        }
        .padding(12)
        .frame(width: 340, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(.regularMaterial)
        .onAppear {
            pickerProfile = manager.selectedProfile
        }
        .onChange(of: manager.selectedProfile) { newProfile in
            pickerProfile = newProfile
        }
    }

    // Primary action

    private var primaryActionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if manager.isSessionActive {
                Button {
                    if manager.options.restoreAppsAfterSession && manager.hasAppsPendingRestore {
                        manager.restorePreviousApps()
                    } else {
                        manager.endGamingSession()
                    }
                } label: {
                    Label(endSessionButtonTitle, systemImage: "arrow.uturn.backward.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

            } else if case .previewing = manager.sessionStatus {
                Button {} label: {
                    Label("Review Window Open…", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(true)

            } else if case .preparing = manager.sessionStatus {
                Button {} label: {
                    Label("Preparing…", systemImage: "clock.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(true)

            } else {
                Button {
                    manager.reviewAndPrepareForGaming()
                } label: {
                    Label("Review & Prepare for Gaming…", systemImage: "gamecontroller.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
    }

    // Profile section

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Picker(
                "Gaming Profile",
                selection: Binding<GamingProfile>(
                    get: { pickerProfile },
                    set: { newProfile in
                        pickerProfile = newProfile
                        manager.selectProfile(newProfile)
                    }
                )
            ) {
                ForEach(GamingProfile.allCases) { profile in
                    Text(profile.label)
                        .tag(profile)
                }
            }
            .pickerStyle(.menu)

            if pickerProfile == .custom {
                Text("Custom uses your saved protected apps.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
            }
        }
    }

    // Status section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: statusSymbol)
                    .imageScale(.small)
                    .foregroundColor(statusColor)

                Text(statusTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let detail = statusDetail {
                    Text("•")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)

                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            if let transientMessage = manager.transientMessage,
               !transientMessage.isEmpty {
                Text(transientMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
                    .padding(.leading, 20)
            }
        }
    }

    // Footer section

    private var footerSection: some View {
        HStack(spacing: 10) {
            Menu {
                Button("Settings…") {
                    SettingsWindowController.show(manager: manager)
                }
                .keyboardShortcut(",", modifiers: .command)

                Divider()

                Button("Check Releases") {
                    if let url = URL(string: "https://github.com/PriorConstruction/zoomies-macos/releases") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button("Reset Welcome Screen") {
                    UserDefaults.standard.set(false, forKey: AppStorageKeys.hasSeenWelcome)
                    UserDefaults.standard.synchronize()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
    }

    // Helpers

    private var endSessionButtonTitle: String {
        if manager.options.restoreAppsAfterSession && manager.hasAppsPendingRestore {
            return "End Session & Restore Apps"
        }

        return "End Gaming Session"
    }

    private var statusSymbol: String {
        switch manager.sessionStatus {
        case .ready:
            return "circle.fill"
        case .previewing:
            return "eye.fill"
        case .preparing:
            return "clock.fill"
        case .active:
            return "gamecontroller.fill"
        case .ended:
            return "checkmark.circle.fill"
        case .restored:
            return "arrow.uturn.backward.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch manager.sessionStatus {
        case .ready, .ended, .restored:
            return .green
        case .previewing, .preparing:
            return .secondary
        case .active:
            return .blue
        case .failed:
            return .orange
        }
    }

    private var statusTitle: String {
        switch manager.sessionStatus {
        case .ready:
            return "Ready"
        case .previewing:
            return "Reviewing"
        case .preparing:
            return "Preparing"
        case .active:
            return "Session Active"
        case .ended:
            return "Ready"
        case .restored:
            return "Ready"
        case .failed:
            return "Issue"
        }
    }

    private var statusDetail: String? {
        switch manager.sessionStatus {
        case .ready, .ended, .restored:
            return nil
        case .previewing(let count):
            return "\(count) app\(count == 1 ? "" : "s") ready to review"
        case .preparing:
            return "Closing background apps"
        case .active(let closedCount):
            return "\(closedCount) app\(closedCount == 1 ? "" : "s") closed"
        case .failed(let message):
            return message
        }
    }
}
