// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import AppKit
import SwiftUI

/// Small non-activating AppKit HUD used for copy/add confirmation feedback.
@MainActor
final class HUDController {
    static let shared = HUDController()

    private var panel: NSPanel?
    private var hideTask: DispatchWorkItem?

    private init() {}

    func show(message: String) {
        let panel = ensurePanel(with: message)

        if let hostingView = panel.contentView as? NSHostingView<HUDView> {
            hostingView.rootView = HUDView(message: message)
            panel.setContentSize(hostingView.fittingSize)
        }

        position(panel)
        hideTask?.cancel()

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 1
        }

        let task = DispatchWorkItem { [weak self] in
            self?.hidePanel(panel)
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95, execute: task)
    }

    private func hidePanel(_ panel: NSPanel) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.orderOut(nil)
        }
    }

    private func ensurePanel(with message: String) -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 46),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true

        let hostingView = NSHostingView(rootView: HUDView(message: message))
        panel.contentView = hostingView
        panel.setContentSize(hostingView.fittingSize)

        self.panel = panel
        return panel
    }

    private func position(_ panel: NSPanel) {
        let mousePoint = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mousePoint, $0.frame, false) }) ?? NSScreen.main

        guard let screen = targetScreen else {
            return
        }

        let frame = screen.visibleFrame
        let width = panel.frame.width
        let height = panel.frame.height

        let proposedX = mousePoint.x - (width / 2)
        let proposedY = mousePoint.y - height - 28

        let minX = frame.minX + 12
        let maxX = frame.maxX - width - 12
        let minY = frame.minY + 12
        let maxY = frame.maxY - height - 12

        let clampedX = min(max(proposedX, minX), maxX)
        let clampedY = min(max(proposedY, minY), maxY)

        panel.setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
    }
}

private struct HUDView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .fixedSize()
    }
}
