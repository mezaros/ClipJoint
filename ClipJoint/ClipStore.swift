// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import AppKit
import Combine
import Foundation

struct TextClip: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var text: String

    init(id: UUID = UUID(), name: String = "", text: String) {
        self.id = id
        self.name = name
        self.text = text
    }

    var menuLabel: String {
        ClipTextFormatter.menuLabel(name: name, text: text, limit: ClipStore.menuLabelCharacterLimit)
    }
}

/// Persistent source of truth for clips plus lightweight clipboard availability caching.
@MainActor
final class ClipStore: ObservableObject {
    static let maximumClipCount = 300
    static let menuLabelCharacterLimit = 25
    static let menuItemHeightEstimate: CGFloat = 22
    static let topLevelMenuFixedItemCountEstimate = 8
    static let menuVerticalPaddingEstimate: CGFloat = 44
    static let clipTextCharacterLimit = 20_000

    @Published private(set) var clips: [TextClip] = [] {
        didSet {
            guard !isHydrating else { return }
            persistClips()
        }
    }

    private let defaults: UserDefaults
    private let storageKey: String
    private var isHydrating = false
    private var clipboardCache: (changeCount: Int, text: String?) = (-1, nil)

    init(defaults: UserDefaults = .standard, storageKey: String = "clipjoint.savedClips.v1") {
        self.defaults = defaults
        self.storageKey = storageKey

        isHydrating = true
        clips = (Self.loadClips(from: defaults, key: storageKey) ?? Self.defaultClips).map(Self.sanitizedClip)
        enforceClipLimit()
        isHydrating = false
        persistClips()
    }

    var hasClips: Bool {
        !clips.isEmpty
    }

    func clip(with id: UUID) -> TextClip? {
        clips.first { $0.id == id }
    }

    func copyClip(_ clip: TextClip) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        _ = pasteboard.setString(clip.text, forType: .string)
        HUDController.shared.show(message: "Copied")
    }

    func addClipboardClip() -> Bool {
        guard let clipboardText = cachedClipboardText(forceRefresh: true) else {
            HUDController.shared.show(message: "Clipboard has no text")
            return false
        }

        return addClip(text: clipboardText)
    }

    func canImportClipboardText(forceRefresh: Bool = false) -> Bool {
        cachedClipboardText(forceRefresh: forceRefresh) != nil
    }

    var canAddAnotherClip: Bool {
        clips.count < maximumClipCount
    }

    var maximumClipCount: Int {
        Self.maximumClipCount
    }

    @discardableResult
    func addBlankClip() -> UUID? {
        guard canAddAnotherClip else {
            HUDController.shared.show(message: "Clip limit reached")
            return nil
        }

        let clip = TextClip(name: "New Clip", text: "")
        clips.append(clip)
        return clip.id
    }

    @discardableResult
    func addClip(text: String) -> Bool {
        guard canAddAnotherClip else {
            HUDController.shared.show(message: "Clip limit reached")
            return false
        }

        guard let normalizedText = ClipboardNormalizer.normalize(text) else {
            return false
        }

        let boundedText = ClipTextFormatter.bounded(normalizedText, maxLength: Self.clipTextCharacterLimit)
        let clipName = ClipTextFormatter.plainPrefix(from: boundedText, limit: Self.menuLabelCharacterLimit)
        clips.append(TextClip(name: clipName, text: boundedText))
        return true
    }

    func updateName(for id: UUID, to name: String) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else {
            return
        }

        clips[index].name = ClipTextFormatter.boundedSingleLineTitle(name, limit: Self.menuLabelCharacterLimit)
    }

    func updateText(for id: UUID, to text: String) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else {
            return
        }

        let normalized = ClipTextFormatter.normalizedLineBreaks(text)
        clips[index].text = ClipTextFormatter.bounded(normalized, maxLength: Self.clipTextCharacterLimit)
    }

    func deleteClip(with id: UUID) {
        clips.removeAll { $0.id == id }
    }

    func canMoveClip(with id: UUID, direction: Int) -> Bool {
        guard let index = clips.firstIndex(where: { $0.id == id }) else {
            return false
        }

        return clips.indices.contains(index + direction)
    }

    func moveClip(with id: UUID, direction: Int) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else {
            return
        }

        let destination = index + direction
        guard clips.indices.contains(destination) else {
            return
        }

        clips.swapAt(index, destination)
    }

    private func persistClips() {
        guard let encoded = try? JSONEncoder().encode(clips) else {
            return
        }

        defaults.set(encoded, forKey: storageKey)
    }

    private func cachedClipboardText(forceRefresh: Bool) -> String? {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        if !forceRefresh, clipboardCache.changeCount == changeCount {
            return clipboardCache.text
        }

        let normalizedText = ClipboardNormalizer.plainTextFromPasteboard(pasteboard)
        clipboardCache = (changeCount, normalizedText)
        return normalizedText
    }

    private static func loadClips(from defaults: UserDefaults, key: String) -> [TextClip]? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode([TextClip].self, from: data)
    }

    private static func sanitizedClip(_ clip: TextClip) -> TextClip {
        var sanitized = clip
        sanitized.name = ClipTextFormatter.boundedSingleLineTitle(clip.name, limit: Self.menuLabelCharacterLimit)
        sanitized.text = ClipTextFormatter.bounded(clip.text, maxLength: Self.clipTextCharacterLimit)
        return sanitized
    }

    private func enforceClipLimit() {
        let limit = maximumClipCount
        guard clips.count > limit else {
            return
        }

        clips = Array(clips.suffix(limit))
    }

    private static let defaultClips: [TextClip] = [
        TextClip(
            name: "Bob's your uncle",
            text: "Bob's your uncle"
        ),
        TextClip(
            name: "Joe Bagodonuts",
            text: "Joe Bagodonuts"
        ),
        TextClip(
            name: "The quick brown fox jumps over the lazy dog",
            text: "The quick brown fox jumps over the lazy dog, or something like that. Honestly, feels kind of mean to shame the dog like this."
        )
    ]
}
