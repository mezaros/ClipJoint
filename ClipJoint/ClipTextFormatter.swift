// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import Foundation

/// Shared text-shaping helpers so menu labels/editor previews stay consistent.
enum ClipTextFormatter {
    private static let menuEmptyPlaceholder = "(Empty Clip)"

    static func normalizedLineBreaks(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    static func collapsedSingleLine(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func menuLabel(name: String, text: String, limit: Int) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmedName.isEmpty ? text : trimmedName
        let collapsed = collapsedSingleLine(source)
        guard !collapsed.isEmpty else {
            return menuEmptyPlaceholder
        }

        return truncatedTail(collapsed, limit: limit)
    }

    static func plainPrefix(from text: String, limit: Int) -> String {
        guard limit > 0 else {
            return ""
        }

        let collapsed = collapsedSingleLine(text)
        guard collapsed.count > limit else {
            return collapsed
        }

        var prefix = String(collapsed.prefix(limit))
        while prefix.last?.isWhitespace == true {
            prefix.removeLast()
        }
        return prefix
    }

    static func preview(_ text: String, limit: Int, emptyPlaceholder: String = "No text yet") -> String {
        guard limit > 0 else {
            return ""
        }

        let collapsed = collapsedSingleLine(text)
        guard !collapsed.isEmpty else {
            return emptyPlaceholder
        }

        guard collapsed.count > limit else {
            return collapsed
        }

        let endIndex = collapsed.index(collapsed.startIndex, offsetBy: limit)
        return String(collapsed[..<endIndex]) + "…"
    }

    static func bounded(_ text: String, maxLength: Int) -> String {
        guard maxLength > 0 else {
            return ""
        }

        guard text.count > maxLength else {
            return text
        }

        return String(text.prefix(maxLength))
    }

    static func boundedSingleLineTitle(_ text: String, limit: Int) -> String {
        guard limit > 0 else {
            return ""
        }

        let singleLine = normalizedLineBreaks(text).replacingOccurrences(of: "\n", with: " ")
        return bounded(singleLine, maxLength: limit)
    }

    private static func truncatedTail(_ text: String, limit: Int) -> String {
        guard limit > 0 else {
            return ""
        }

        guard text.count > limit else {
            return text
        }

        var prefix = String(text.prefix(limit))
        while prefix.last?.isWhitespace == true {
            prefix.removeLast()
        }
        return prefix + "…"
    }
}
