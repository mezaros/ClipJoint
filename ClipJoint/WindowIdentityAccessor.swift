// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import AppKit
import SwiftUI

/// Bridges a SwiftUI scene to an AppKit window identifier for reliable focusing.
struct WindowIdentityAccessor: NSViewRepresentable {
    let id: String

    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else {
                return
            }

            if window.identifier?.rawValue != id {
                window.identifier = NSUserInterfaceItemIdentifier(id)
            }
        }
    }
}
