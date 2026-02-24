# ClipJoint

## Introduction

ClipJoint is a lightweight macOS menu bar app for saving frequently used text snippets ("clips") and copying them back to the clipboard in one click. One click copies anything to the ClipJoint menu, and one click copies anything back to the clipboard. Think of it like TextExpander (or the Mac's built-in Text Replacements), putting frequently used text clips at your fingertips, only purely visual and far less capable.

That's it. That's the app.

## Why It Exists

I built ClipJoint for two reasons: to fill a personal need, and to experiment with the world of AI coding assistants. While I'm technical and have done plenty of light scripting (Python and the like), I'm not a true developer. I don't know Swift. I don't know the MacOS APIs. I don't really know best practices, on the Mac or even for coding in general. I don't even have a developer account (which is why MacOS will warn you this is malware, more on that below). I've used AI for scripting over the past three years, but never a real coding assistant. I decided to use OpenAI Codex to write an entire utility without looking at a single line of code. Pure vibes.

A usable app was ready after two interactions with the 5.3-Codex model set to Extra High reasoning. That probably took 15-20 minutes. A few hours of fiddling, over the course of two days, worked out some kinks and refined the design into something approximating a reasonable Mac app. To me, given my complete lack of knowledge in this space, that seems fairly magical (and fairly frightening). The app icon comes from a regular ChatGPT session, while the menu bar icon was adapted (by Codex) from the SF Symbols clipboard glyph.

Is the code spaghetti? Is it the worst written Mac app in history? I have no idea. I've barely looked at the code. If you actually know what you're doing, I'd love to hear your take on it.

What little I know: the app is written in Swift 5 and uses a mixture of SwiftUI and AppKit, as (allegedly) certain things could only be done in AppKit. No idea if that's true. I've asked Codex to explain how it works. See `/CODEX.md`.

## Overview

ClipJoint is intentionally (for now, anyway) not a clipboard history manager. It stores only the clips you explicitly keep.

- Menu bar-only workflow.
- Text focused. Rich text or similar is boiled down to plain text; this app only deals with plain text.
- Dedicated **Edit Clips** window lets you revise, rearrange, or delete clips.
- Can be set to launch at login (check out the expansive Settings window).
- Clip titles are truncated, and bound to 25 characters when edited/saved.
- Maximum clip text length: 20,000 characters per clip.
- Maximum number of clips: 200. If the menu covers too much of your screen, a "More" submenu will appear (which, if content demands, eventually becomes scrollable).

## Not Malware

ClipJoint isn't malware (I mean, I'm pretty sure?). But because I don't have a developer account, the binaries are self-signed. If you build the app yourself, self-sign or use your own developer account. To run the pre-made binary, you'll need to control-click the app, dismiss the warning, then head to System Settings -> Privacy & Security and overrride the warning, and then agree to open anyway when MacOS alerts you.

## Room for Improvement

Lots of things that could be done here, if somebody wanted to:

- Optionally allow rich text, HTML, or even purely non-text clips.
- Optional keyboard shortcut assignment for each clip.
- Allow custom-set widths for the menus (instead of always truncating clip titles at 25 characters).
- Add basic clipboard management features (i.e. automatic clipboard history).
- Properly signed releases, like a real grown-up boy.
- Automatic updates.

## Build and Run

### Requirements

- macOS 15.7+
- Xcode 17+

### Xcode

1. Open `ClipJoint.xcodeproj`.
2. Select the `ClipJoint` scheme.
3. Build and run.

You probably will want to customize the project settings. Current settings place the built app in:

- `/Applications/ClipJoint.app`

## License

- Project is licensed under GPL 2.0.
- Full license text: `/LICENSE.txt`
