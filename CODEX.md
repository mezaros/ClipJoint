# CODEX Development Report: ClipJoint

Author: CODEX

This document is a development-focused report from CODEX describing how ClipJoint is built, how it behaves, and why key implementation decisions were made.

## 1. Project Summary

ClipJoint is a macOS menu bar utility for user-curated text snippets. It is deliberately scoped to explicit, saved clips rather than clipboard history capture.

Primary goals:

- Fast one-click copy from menu bar.
- Minimal UI footprint with native macOS behaviors.
- Reliable persistence with simple local storage.
- Lightweight architecture with clear separation of concerns.

## 2. High-Level Architecture

Core stack:

- SwiftUI for app lifecycle, scenes, menus, and editor/settings UI.
- Targeted AppKit interoperability for APIs SwiftUI does not provide directly.

Main files and roles:

- `ClipJoint/ClipJointApp.swift`
  - App entry point.
  - Declares `MenuBarExtra`, `Edit Clips` window, `Settings` window.
  - Wires `ClipStore` and `AppSettings` as environment objects.
- `ClipJoint/ClipMenuView.swift`
  - Menu content and command behavior.
  - Handles About panel, Settings/Edit window focus, add/copy actions.
  - Refreshes clipboard-dependent menu enable state when menu opens.
- `ClipJoint/ClipStore.swift`
  - Main model/store and persistence layer.
  - Owns clips array, add/update/delete/move logic, limits, caching.
- `ClipJoint/ClipsEditorView.swift`
  - Full clip management UI.
  - Supports add blank, add from clipboard, reorder, delete, disclosure editing.
- `ClipJoint/SettingsView.swift`, `ClipJoint/AppSettings.swift`
  - Launch-at-login preference and ServiceManagement integration.
- `ClipJoint/ClipboardNormalizer.swift`
  - Converts pasteboard content to plain normalized text.
- `ClipJoint/ClipTextFormatter.swift`
  - Text shaping helpers for labels/previews/length bounds.
- `ClipJoint/HUDController.swift`
  - AppKit non-activating HUD for transient status feedback.
- `ClipJoint/WindowIdentityAccessor.swift`
  - Window identity bridge to support reliable focus behavior.

## 3. Runtime Flow

### 3.1 App startup

1. App initializes `ClipStore` and `AppSettings`.
2. `ClipStore` loads clips from `UserDefaults` (`clipjoint.savedClips.v1`).
3. If no saved data, defaults are seeded.
4. Clip limit is enforced based on current display height.
5. Menu bar icon appears and menu content is ready.

### 3.2 Copy flow

1. User selects a clip menu item.
2. `ClipStore.copyClip(_:)` writes clip text to `NSPasteboard`.
3. HUD shows `Copied` via `HUDController`.

### 3.3 Add-from-clipboard flow

1. User selects `Add Clip from Clipboard` (menu or editor).
2. Clipboard text is fetched/normalized through `ClipboardNormalizer`.
3. Store validates limits, bounds text length, derives initial name.
4. Clip is appended to the end.
5. HUD feedback appears (`Clip Added` or an explanatory message).

### 3.4 Edit flow

- Title edits are bounded to a single line and max title length.
- Content edits preserve line breaks and are bounded by max clip length.
- Reordering swaps items up/down.
- Deletion removes clip and persistence updates automatically.

### 3.5 Window focus flow

- Menu actions for Settings/Edit attempt to focus existing windows first.
- If not found, `openWindow(id:)` is used.
- `WindowIdentityAccessor` ensures backing `NSWindow.identifier` matches scene IDs for stable lookup.

## 4. Data Model and Persistence

### 4.1 TextClip

`TextClip` includes:

- `id: UUID`
- `name: String`
- `text: String`

`menuLabel` is computed from title/content using formatter rules.

### 4.2 Storage

- Persisted as JSON in `UserDefaults`.
- Key: `clipjoint.savedClips.v1`.
- Persistence occurs automatically via `@Published` `didSet` (except during hydration).

### 4.3 Default clips

The app seeds three defaults on first run:

1. `Bob's your uncle`
2. `Joe Bagodonuts`
3. The long quick-brown-fox sentence

## 5. Constraints and Limits

Configured constraints:

- Menu label character limit: `25`
- Clip text character limit: `20,000`
- Max number of clips: computed dynamically from screen/menu height estimates

Rationale:

- Prevent menu overflow off-screen.
- Keep UI responsive and predictable.
- Bound untrusted clipboard payload size.

## 6. SwiftUI vs AppKit: Why the split exists

SwiftUI is the default implementation layer, but AppKit is used intentionally for macOS-specific capabilities:

- `NSPasteboard` for robust clipboard integration.
- `NSApp.orderFrontStandardAboutPanel` for native About behavior.
- `NSPanel` for a lightweight non-activating HUD.
- `NSMenu.didBeginTrackingNotification` for menu-open timing and enable-state reconciliation.
- `NSWindow` identity/focus interop not fully exposed in pure SwiftUI.

This is a deliberate hybrid approach: SwiftUI for structure and state, AppKit where direct control is needed.

## 7. UX and Behavior Decisions

### 7.1 Menu item truncation

Menu labels are shown in a fixed-width text frame with tail truncation. This delegates visible truncation behavior to system text rendering while keeping menu width stable.

### 7.2 Clipboard enable-state refresh

The menu opens quickly with last-known state, then refreshes add-item enablement immediately and again after a short delay. This reduces stale state caused by pasteboard timing while avoiding constant background polling.

### 7.3 Editor disclosure model

Clip text is hidden behind disclosure rows by default to reduce cognitive load and maintain a compact list. New blank clips auto-expand to reduce clicks.

### 7.4 Launch-at-login behavior

`SMAppService.mainApp` is used as the system-preferred API. Errors are surfaced with actionable text (approval required, app location requirements, etc.).

## 8. Naming and Refactors applied

Recent cleanup included renaming `CopiedHUDController` to `HUDController` to better match actual usage across all transient messages (`Copied`, `Clip Added`, validation failures).

## 9. Known Technical Risks / Tradeoffs

- Dynamic menu clip limit is estimate-based; unusual menu metrics or accessibility font scaling can affect exact fit.
- Window identity bridging (`WindowIdentityAccessor`) is interop-driven; functional but less elegant than a pure SwiftUI API that does not currently exist for this use case.
- Clipboard content normalization intentionally prefers textual payloads and ignores non-text objects.

## 10. Recommended Next Improvements (non-breaking)

1. Extract newline normalization into a dedicated shared utility to reduce coupling (`ClipboardNormalizer` currently calls into `ClipTextFormatter`).
2. Add unit tests for formatter rules and clip-limit computation logic.
3. Add lightweight integration tests for add/copy/menu-enable behavior.
4. Consider introducing structured logging hooks for support diagnostics.

## 11. Release Readiness Assessment

From the current implementation perspective:

- Architecture is coherent and maintainable.
- Responsibilities are mostly well-separated.
- User-facing flows match product intent.
- Critical macOS behaviors (menu, clipboard, window focus, login item) are covered.

Remaining improvements are mostly around test coverage and minor layering cleanup, not core functionality gaps.

