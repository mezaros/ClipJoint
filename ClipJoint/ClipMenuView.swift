// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import AppKit
import SwiftUI

/// SwiftUI menu content with narrowly scoped AppKit interop for menu state and window focus.
struct ClipMenuView: View {
    @EnvironmentObject private var clipStore: ClipStore
    @Environment(\.openWindow) private var openWindow
    @State private var menuClipboardHasText = true
    private static let addClipMenuTitle = "Add Clip from Clipboard"
    private static let topLevelMenuScreenFraction: CGFloat = 3.0 / 4.0

    private static let menuLabelWidth: CGFloat = {
        let sample = String(repeating: "x", count: ClipStore.menuLabelCharacterLimit)
        let font = NSFont.menuFont(ofSize: 0)
        return ceil((sample as NSString).size(withAttributes: [.font: font]).width)
    }()

    var body: some View {
        Group {
            Button("About ClipJoint") {
                showAboutPanel()
            }

            Button("Settings…") {
                showSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            if clipStore.hasClips {
                let clipMenuSections = partitionedClipMenuSections(clips: clipStore.clips)

                ForEach(clipMenuSections.primary) { clip in
                    Button {
                        clipStore.copyClip(clip)
                    } label: {
                        Text(clip.menuLabel)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: Self.menuLabelWidth, alignment: .leading)
                    }
                    .help(ClipTextFormatter.preview(clip.text, limit: 240, emptyPlaceholder: "(Empty Clip)"))
                }

                if !clipMenuSections.overflow.isEmpty {
                    Menu("More") {
                        ForEach(clipMenuSections.overflow) { clip in
                            Button {
                                clipStore.copyClip(clip)
                            } label: {
                                Text(clip.menuLabel)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(width: Self.menuLabelWidth, alignment: .leading)
                            }
                            .help(ClipTextFormatter.preview(clip.text, limit: 240, emptyPlaceholder: "(Empty Clip)"))
                        }
                    }
                }
            } else {
                Text("No saved clips")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(Self.addClipMenuTitle) {
                if clipStore.addClipboardClip() {
                    HUDController.shared.show(message: "Clip Added")
                }
                updateAddClipAvailability()
            }
            .disabled(!menuClipboardHasText || !clipStore.canAddAnotherClip)

            Button("Edit Clips…") {
                showClipsEditorWindow()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .onAppear(perform: updateAddClipAvailability)
        .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { notification in
            handleMenuDidBeginTracking(notification)
        }
    }

    private func showAboutPanel() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let appIcon: NSImage = NSImage(named: NSImage.applicationIconName) ?? NSApplication.shared.applicationIconImage
        let options: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationVersion: appVersion,
            .version: "",
            .applicationIcon: appIcon
        ]
        NSApp.orderFrontStandardAboutPanel(options: options)
    }

    private func showSettingsWindow() {
        showWindow(id: AppSceneID.settings, fallbackTitle: "Settings")
    }

    private func showClipsEditorWindow() {
        showWindow(id: AppSceneID.clipsEditor, fallbackTitle: "Edit Clips")
    }

    private func showWindow(id: String, fallbackTitle: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if focusWindow(id: id, fallbackTitle: fallbackTitle) {
            return
        }

        openWindow(id: id)

        DispatchQueue.main.async {
            _ = focusWindow(id: id, fallbackTitle: fallbackTitle)
        }
    }

    private func focusWindow(id: String, fallbackTitle: String) -> Bool {
        let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == id })
            ?? NSApplication.shared.windows.first(where: { $0.title == fallbackTitle })

        guard let window else {
            return false
        }

        if window.identifier?.rawValue != id {
            window.identifier = NSUserInterfaceItemIdentifier(id)
        }

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        return true
    }

    private func updateAddClipAvailability() {
        menuClipboardHasText = clipStore.canImportClipboardText(forceRefresh: true)
    }

    private func handleMenuDidBeginTracking(_ notification: Notification) {
        guard let menu = notification.object as? NSMenu, addClipMenuItem(in: menu) != nil else {
            return
        }

        // Open fast using last known state, then reconcile with live pasteboard state.
        applyAddClipEnabledState(to: menu, hasClipboardText: menuClipboardHasText)

        DispatchQueue.main.async {
            refreshAddClipEnabledState(in: menu)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            refreshAddClipEnabledState(in: menu)
        }
    }

    private func refreshAddClipEnabledState(in menu: NSMenu) {
        let hasClipboardText = clipStore.canImportClipboardText(forceRefresh: true)
        menuClipboardHasText = hasClipboardText
        applyAddClipEnabledState(to: menu, hasClipboardText: hasClipboardText)
    }

    private func applyAddClipEnabledState(to menu: NSMenu, hasClipboardText: Bool) {
        let isEnabled = hasClipboardText && clipStore.canAddAnotherClip
        addClipMenuItem(in: menu)?.isEnabled = isEnabled
    }

    private func addClipMenuItem(in menu: NSMenu) -> NSMenuItem? {
        menu.items.first(where: { $0.title == Self.addClipMenuTitle })
    }

    private func partitionedClipMenuSections(clips: [TextClip]) -> (primary: [TextClip], overflow: [TextClip]) {
        let topLevelBudget = topLevelClipRowBudget()
        guard clips.count > topLevelBudget else {
            return (clips, [])
        }

        // Reserve one top-level row for the "More" submenu.
        let primaryCount = max(0, topLevelBudget - 1)
        return (Array(clips.prefix(primaryCount)), Array(clips.dropFirst(primaryCount)))
    }

    private func topLevelClipRowBudget() -> Int {
        let mousePoint = NSEvent.mouseLocation
        let currentScreen = NSScreen.screens.first(where: { NSMouseInRect(mousePoint, $0.frame, false) }) ?? NSScreen.main
        let visibleHeight = currentScreen?.visibleFrame.height ?? 900
        let maxTopLevelMenuHeight = visibleHeight * Self.topLevelMenuScreenFraction
        let fixedHeight = (CGFloat(ClipStore.topLevelMenuFixedItemCountEstimate) * ClipStore.menuItemHeightEstimate)
            + ClipStore.menuVerticalPaddingEstimate
        let clipRows = Int(floor(max(0, maxTopLevelMenuHeight - fixedHeight) / ClipStore.menuItemHeightEstimate))
        return max(1, clipRows)
    }
}
