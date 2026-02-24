// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import SwiftUI

struct ClipsEditorView: View {
    @EnvironmentObject private var clipStore: ClipStore
    @State private var expandedClipIDs: Set<UUID> = []
    @State private var pendingScrollClipID: UUID?
    private let windowWidth: CGFloat = 630
    private let windowHeight: CGFloat = 560
    private let horizontalInset: CGFloat = 22
    private let trailingInset: CGFloat = 28
    private let topControlsTrailingInset: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Spacer()

                Button("Add Blank Clip") {
                    guard let clipID = clipStore.addBlankClip() else {
                        return
                    }
                    expandedClipIDs.insert(clipID)
                    pendingScrollClipID = clipID
                }
                .disabled(!clipStore.canAddAnotherClip)

                Button("Add Clip from Clipboard") {
                    let wasAdded = clipStore.addClipboardClip()
                    if wasAdded, let clipID = clipStore.clips.last?.id {
                        pendingScrollClipID = clipID
                    }
                }
                .disabled(!clipStore.canAddAnotherClip)
            }
            .padding(.trailing, topControlsTrailingInset)

            if clipStore.clips.isEmpty {
                ContentUnavailableView(
                    "No Clips Yet",
                    systemImage: "doc.on.clipboard",
                    description: Text("Use Add Clip from the menu bar menu to stash text snippets.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(clipStore.clips) { clip in
                                ClipRow(
                                    name: nameBinding(for: clip.id),
                                    text: textBinding(for: clip.id),
                                    isExpanded: expandedBinding(for: clip.id),
                                    canMoveUp: clipStore.canMoveClip(with: clip.id, direction: -1),
                                    canMoveDown: clipStore.canMoveClip(with: clip.id, direction: 1),
                                    onMoveUp: { clipStore.moveClip(with: clip.id, direction: -1) },
                                    onMoveDown: { clipStore.moveClip(with: clip.id, direction: 1) },
                                    onDelete: {
                                        expandedClipIDs.remove(clip.id)
                                        clipStore.deleteClip(with: clip.id)
                                    }
                                )
                                .id(clip.id)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .padding(.trailing, 8)
                    }
                    .scrollIndicators(.visible)
                    .onChange(of: pendingScrollClipID) { _, clipID in
                        guard let clipID else { return }
                        withAnimation {
                            scrollProxy.scrollTo(clipID, anchor: .bottom)
                        }
                        pendingScrollClipID = nil
                    }
                }
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 18)
        .padding(.leading, horizontalInset)
        .padding(.trailing, trailingInset)
        .frame(width: windowWidth, height: windowHeight, alignment: .topLeading)
    }

    private func nameBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { clipStore.clip(with: id)?.name ?? "" },
            set: { clipStore.updateName(for: id, to: $0) }
        )
    }

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { clipStore.clip(with: id)?.text ?? "" },
            set: { clipStore.updateText(for: id, to: $0) }
        )
    }

    private func expandedBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedClipIDs.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedClipIDs.insert(id)
                } else {
                    expandedClipIDs.remove(id)
                }
            }
        )
    }
}

private struct ClipRow: View {
    @Binding var name: String
    @Binding var text: String
    @Binding var isExpanded: Bool

    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                TextField("Clip Name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Button(action: onMoveUp) {
                    Image(systemName: "arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveUp)
                .help("Move clip up")

                Button(action: onMoveDown) {
                    Image(systemName: "arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveDown)
                .help("Move clip down")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help("Delete clip")
            }

            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    TextEditor(text: $text)
                        .font(.body)
                        .frame(minHeight: 120)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(nsColor: .textBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 1)
                        )
                },
                label: {
                    Text(ClipTextFormatter.preview(text, limit: 90))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 1)
        )
    }
}
