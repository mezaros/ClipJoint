# ClipJoint

## Introduction

> Add your project introduction here.
>
> Suggested content:
> - What ClipJoint is for
> - Who it is for
> - Why it exists

## Overview

ClipJoint is a lightweight macOS menu bar app for saving frequently used text snippets and copying them back to the clipboard in one click.

It is intentionally not a clipboard history manager. It stores only the clips you explicitly keep.

## Key Features

- Menu bar-only workflow with a custom clipboard icon.
- One-click copy from the menu (`Copied` HUD confirmation).
- Add clip from current clipboard text (`Clip Added` HUD confirmation).
- Dedicated **Edit Clips** window with:
  - Rename clip title
  - Edit clip content (via disclosure)
  - Reorder clips (up/down)
  - Delete clips
  - Add blank clip
  - Add clip from clipboard
- **Settings** window with launch-at-login support.
- Native About panel with app icon.
- Persistent storage of clips between launches.
- Practical clip count limit with top-level menu overflow into a `More` submenu.

## Defaults on Fresh Install

A new user starts with three clips:

1. `Bob's your uncle`
2. `Joe Bagodonuts`
3. `The quick brown fox jumps over the lazy dog, or something like that. Honestly, feels kind of mean to shame the dog like this.`

## Product Behavior

### Menu

Menu order:

1. About ClipJoint
2. Settings...
3. Clip entries (top-level budgeted by screen height)
4. More (shown only when clips overflow top-level budget)
5. Add Clip from Clipboard
6. Edit Clips...
7. Quit

### Clip naming and menu labels

- Clip titles are bounded to `25` characters when edited/saved.
- Menu entries use a fixed width and tail truncation so long labels remain compact.
- If a clip title is empty, the menu label falls back to the beginning of clip content.

### Clipboard ingest

When adding from clipboard, ClipJoint attempts to normalize text in this order:

1. Plain text (`public.utf8-plain-text`)
2. `NSAttributedString` content
3. RTF
4. HTML

If no usable text exists, add actions are disabled or no clip is created.

### Limits

- Maximum clip text length: `20,000` characters per clip.
- Maximum number of clips: `300`.
- Top-level menu clipping: if estimated height exceeds `3/4` of visible screen height, extra clips move into `More`.

## Architecture

### Tech stack

- Swift 5
- SwiftUI app lifecycle and primary UI
- Focused AppKit interop where SwiftUI alone is not sufficient

### SwiftUI vs AppKit split

SwiftUI handles:

- App scenes/windows
- Menu content structure
- Editor and settings UI
- Data binding/state flow

AppKit handles:

- Pasteboard access (`NSPasteboard`)
- About panel (`NSApp.orderFrontStandardAboutPanel`)
- Non-activating HUD panel (`NSPanel`) for copy/add feedback
- Reliable menu-open timing hooks (`NSMenu.didBeginTrackingNotification`)
- Window focusing/identity bridging

### Core source files

- `ClipJoint/ClipJointApp.swift`: App scenes, menu bar entry point, commands.
- `ClipJoint/ClipMenuView.swift`: Menu content, overflow partitioning, window focus behavior, add/copy actions.
- `ClipJoint/ClipStore.swift`: Clip model, persistence, limits, ordering, clipboard caching.
- `ClipJoint/ClipsEditorView.swift`: Full clip editor UI.
- `ClipJoint/SettingsView.swift`: Launch-at-login setting UI.
- `ClipJoint/AppSettings.swift`: Login-item service integration.
- `ClipJoint/ClipboardNormalizer.swift`: Clipboard text normalization pipeline.
- `ClipJoint/ClipTextFormatter.swift`: Label/title/preview shaping and truncation helpers.
- `ClipJoint/HUDController.swift`: HUD presentation and animation.

## Build and Run

### Requirements

- macOS 15.7+
- Xcode 17+

### Xcode

1. Open `ClipJoint.xcodeproj`.
2. Select the `ClipJoint` scheme.
3. Build and run.

Current project settings place the built app in:

- `/Applications/ClipJoint.app`

### Command line build

From repository root:

```bash
xcodebuild -project ClipJoint.xcodeproj -scheme ClipJoint -destination 'platform=macOS' build
```

## Settings and Login Item

- Setting label: `Launch automatically at login`.
- Default for new users: off.
- Uses `ServiceManagement` (`SMAppService.mainApp`) for registration.
- If registration needs user approval, macOS prompts/flags in System Settings.

## Data Storage

Clip data is persisted in `UserDefaults` under:

- `clipjoint.savedClips.v1`

## Privacy and Permissions

ClipJoint does **not** require Accessibility permissions.

It reads clipboard data only for explicit clip actions and menu availability checks.

## Keyboard Shortcuts

- Settings: `Cmd + ,`
- Quit: `Cmd + Q`

## Testing Checklist (Manual)

- Menu opens and clip list renders with truncation.
- Clicking a clip copies text and shows `Copied` HUD.
- `Add Clip from Clipboard` enables/disables based on clipboard text.
- Adding from menu appends to bottom.
- Editor add/reorder/delete updates menu immediately.
- Editor disclosure state works (including new blank clip expansion).
- Settings and Edit Clips actions focus existing windows when already open.
- Launch-at-login toggle updates correctly.
- App icon appears in Dock/About panel; menu bar icon remains template-readable in light/dark mode.

## Troubleshooting

- If launch-at-login fails, install/run from `/Applications` and retry.
- If menu add action appears stale, reopen the menu once to force a fresh clipboard reconciliation.
- If icon changes do not appear, fully quit ClipJoint and relaunch from `/Applications/ClipJoint.app`.

## License

- Project is licensed under GPL 2.0.
- Full license text: `LICENSE`
