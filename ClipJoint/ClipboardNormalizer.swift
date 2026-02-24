// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import AppKit
import Foundation

/// Converts pasteboard payloads into plain, normalized text suitable for clip storage.
enum ClipboardNormalizer {
    static func plainTextFromPasteboard(_ pasteboard: NSPasteboard = .general) -> String? {
        if let plain = pasteboard.string(forType: .string), let normalized = normalize(plain) {
            return normalized
        }

        if let attributed = pasteboard.readObjects(forClasses: [NSAttributedString.self], options: nil)?.first as? NSAttributedString,
           let normalized = normalize(attributed.string) {
            return normalized
        }

        if let rtfData = pasteboard.data(forType: .rtf),
           let extracted = attributedText(from: rtfData, documentType: .rtf),
           let normalized = normalize(extracted) {
            return normalized
        }

        if let htmlData = pasteboard.data(forType: .html),
           let extracted = attributedText(from: htmlData, documentType: .html),
           let normalized = normalize(extracted) {
            return normalized
        }

        return nil
    }

    static func normalize(_ text: String) -> String? {
        let normalized = ClipTextFormatter.normalizedLineBreaks(text)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return normalized.isEmpty ? nil : normalized
    }

    private static func attributedText(from data: Data, documentType: NSAttributedString.DocumentType) -> String? {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: documentType
        ]

        guard let attributedString = try? NSAttributedString(
            data: data,
            options: options,
            documentAttributes: nil
        ) else {
            return nil
        }

        return attributedString.string
    }
}
