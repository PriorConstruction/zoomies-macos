//
//  WelcomeView.swift
//  Zoomies-macOS
//
//  Created by Daniel @ Zoomies
//

// The first run onboarding that is to explain what Zoomies does.

import SwiftUI
import AppKit

struct WelcomeView: View {
    let onContinue: () -> Void
    // Keep everything easy to read and scan during first launch.
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 14) {
                Image("Zoomies")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Zoomies")
                        .font(.system(size: 30, weight: .semibold))

                    Text("A lightweight gaming session utility for macOS")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                infoRow(
                    icon: "gamecontroller.fill",
                    title: "Prepare your Mac for gaming",
                    text: "Zoomies closes unnecessary background apps while preserving your chosen launchers, Discord, screen recording apps and gaming peripheral software."
                )

                infoRow(
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    title: "Restore apps when you're done",
                    text: "Closed apps can be restored at the end of your session. This is enabled by default and can be changed at any time from the Options menu."
                )

                infoRow(
                    icon: "checkmark.shield.fill",
                    title: "Safe and transparent",
                    text: "Zoomies does not modify system files, inject into games or replace macOS Game Mode."
                )
                // Easy way to view source/updates of Zoomies.
                Link("View source & releases at http://www.zoomiesformacos.com", destination: URL(string: "http://www.zoomiesformacos.com")!)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
             
            HStack {
                Button("Quit") { // This will terminate Zoomies. 
                    NSApplication.shared.terminate(nil)
                }

                Spacer()
                // This will proceed to running Zoomies.
                Button("Continue") {
                    onContinue()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 560, height: 370)
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
