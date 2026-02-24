// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import AppKit
import SwiftUI

enum AppSceneID {
    static let clipsEditor = "clips-editor"
    static let settings = "settings-window"
}

@main
struct ClipJointApp: App {
    @StateObject private var clipStore = ClipStore()
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        MenuBarExtra {
            ClipMenuView()
                .environmentObject(clipStore)
                .environmentObject(appSettings)
        } label: {
            ClipboardMenuIcon()
                .accessibilityLabel("ClipJoint")
        }
        .menuBarExtraStyle(.menu)

        Window("Edit Clips", id: AppSceneID.clipsEditor) {
            ClipsEditorView()
                .environmentObject(clipStore)
                .background(
                    WindowIdentityAccessor(id: AppSceneID.clipsEditor)
                        .frame(width: 0, height: 0)
                )
        }
        .defaultSize(width: 630, height: 560)
        .windowResizability(.contentSize)

        Window("Settings", id: AppSceneID.settings) {
            SettingsView()
                .environmentObject(appSettings)
                .background(
                    WindowIdentityAccessor(id: AppSceneID.settings)
                        .frame(width: 0, height: 0)
                )
        }
        .defaultSize(width: 470, height: 170)
        .windowResizability(.contentSize)
        .commands {
            ClipJointCommands()
        }
    }
}

private struct ClipJointCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: AppSceneID.settings)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

private struct ClipboardMenuIcon: View {
    var body: some View {
        Image("MenuBarClipboard")
            .renderingMode(.template)
            .frame(width: 18, height: 18)
    }
}
